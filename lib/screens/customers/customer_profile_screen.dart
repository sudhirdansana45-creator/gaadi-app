import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';

class CustomerProfileScreen extends StatefulWidget {
  final Customer? customer;
  final String? customerId;
  final VoidCallback onBack;

  const CustomerProfileScreen({
    super.key,
    this.customer,
    this.customerId,
    required this.onBack,
  });

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Customer? _customer;
  bool _isLoadingCustomer = false;
  late bool _isBlacklisted;
  late TextEditingController _reasonController;
  List<Booking> _customerBookings = [];
  bool _isLoadingBookings = false;

  Customer get currentCustomer => _customer!;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _isBlacklisted = widget.customer?.isBlacklisted ?? false;
    _reasonController = TextEditingController(text: widget.customer?.blacklistReason ?? '');

    if (_customer == null && widget.customerId != null) {
      _loadCustomer();
    } else if (_customer != null) {
      _loadBookings();
    }
  }

  Future<void> _loadCustomer() async {
    setState(() => _isLoadingCustomer = true);
    try {
      final res = await ApiService().getCustomerDetail(widget.customerId!);
      if (res != null && res['data'] != null && mounted) {
        final c = Customer.fromJson(res['data'] as Map<String, dynamic>);
        setState(() {
          _customer = c;
          _isBlacklisted = c.isBlacklisted;
          _reasonController.text = c.blacklistReason ?? '';
        });
        _loadBookings();
        return;
      }

      final allRes = await ApiService().getCustomers();
      if (allRes != null && allRes['data'] is List && mounted) {
        final list = (allRes['data'] as List)
            .map((item) => Customer.fromJson(item as Map<String, dynamic>))
            .toList();
        final match = list.where((c) => c.id == widget.customerId).firstOrNull;
        if (match != null) {
          setState(() {
            _customer = match;
            _isBlacklisted = match.isBlacklisted;
            _reasonController.text = match.blacklistReason ?? '';
          });
          _loadBookings();
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingCustomer = false);
    }
  }

  Future<void> _loadBookings() async {
    if (_customer == null) return;
    setState(() => _isLoadingBookings = true);
    try {
      final res = await ApiService().getBookings();
      if (res != null && res['data'] is List) {
        final list = (res['data'] as List)
            .map((item) => Booking.fromJson(item as Map<String, dynamic>))
            .where((b) {
              final phoneClean = currentCustomer.phone.replaceAll(' ', '').replaceAll('+91', '');
              final bPhoneClean = b.customerPhone.replaceAll(' ', '').replaceAll('+91', '');
              return (b.customerId != null && b.customerId == currentCustomer.id) ||
                  (phoneClean.isNotEmpty && bPhoneClean.contains(phoneClean)) ||
                  b.customerName.toLowerCase() == currentCustomer.name.toLowerCase();
            })
            .toList();
        if (mounted) {
          setState(() {
            _customerBookings = list;
          });
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingBookings = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _showDocumentPreview(String docTitle, String docNumber, String imgUrl) {
    AppBottomSheet.show(
      context: context,
      title: docTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.canvasLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.badge_rounded, size: 48, color: AppColors.primaryCyan),
                      const SizedBox(height: 8),
                      Text(
                        docTitle,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Document ID: $docNumber',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              StatusChip.verified(label: 'Identity Verified'),
              const Spacer(),
              Text('Doc No: $docNumber', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
      primaryActionText: 'Close Preview',
      onPrimaryAction: () => Navigator.pop(context),
    );
  }

  void _showReplaceDocumentSheet(String docTitle) {
    AppBottomSheet.show(
      context: context,
      title: 'Replace $docTitle',
      content: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryCyan),
            title: const Text('Take Photo with Camera', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Camera opened for $docTitle upload preview'),
                  backgroundColor: AppColors.surfaceCard,
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderHairline),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryCyan),
            title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Selected new image file for $docTitle'),
                  backgroundColor: AppColors.surfaceCard,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _updateBlacklistStatus() {
    if (_customer == null) return;
    setState(() {
      currentCustomer.isBlacklisted = _isBlacklisted;
      currentCustomer.blacklistReason = _isBlacklisted ? _reasonController.text : null;
    });

    try {
      ApiService().toggleCustomerBlacklist(
        currentCustomer.id,
        isBlacklisted: _isBlacklisted,
        reason: _reasonController.text.trim(),
      );
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBlacklisted
              ? 'Customer has been added to Blacklist.'
              : 'Customer has been removed from Blacklist.',
        ),
        backgroundColor: _isBlacklisted ? AppColors.criticalRed : AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCustomer) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Customer Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
      );
    }

    if (_customer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Customer Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.criticalRed.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_off_rounded, color: AppColors.criticalRed, size: 48),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.customerId != null
                      ? 'Customer #${widget.customerId} Not Found'
                      : 'Customer Record Not Found',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The requested customer record does not exist on your account or may have been removed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Back to Customers',
                  width: 180,
                  onPressed: widget.onBack,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isBlacklisted
                      ? AppColors.criticalBg.withValues(alpha: 0.3)
                      : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isBlacklisted ? AppColors.criticalBorder : AppColors.borderSubtle,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: _isBlacklisted ? AppColors.criticalBg : AppColors.primaryCyan,
                          child: Text(
                            currentCustomer.name.isNotEmpty
                                ? currentCustomer.name.substring(0, currentCustomer.name.length >= 2 ? 2 : 1).toUpperCase()
                                : 'CU',
                            style: TextStyle(
                              color: _isBlacklisted ? AppColors.criticalRed : AppColors.textDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    currentCustomer.name,
                                    style: TextStyle(
                                      color: _isBlacklisted ? AppColors.criticalRed : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.successBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      currentCustomer.rating,
                                      style: const TextStyle(
                                        color: AppColors.successGreen,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (_isBlacklisted)
                                    StatusChip.blacklisted()
                                  else if (currentCustomer.isVerified)
                                    StatusChip.verified(),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(currentCustomer.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              Text(currentCustomer.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.borderHairline),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _kpi('Total Trips', '${currentCustomer.totalRentals}'),
                        _kpi('Lifetime Spent', '₹${currentCustomer.totalSpent.toInt()}'),
                        _kpi('Balance Due', '₹${currentCustomer.outstandingBalance.toInt()}', isWarning: currentCustomer.outstandingBalance > 0),
                      ],
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 16),

          // KYC & Identity Documents Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppColors.primaryCyan, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Verified Identity & KYC Documents',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _infoRow('Driving License:', currentCustomer.drivingLicense),
                _infoRow('Registered Address:', currentCustomer.address),
                _infoRow('Verification Status:', currentCustomer.isVerified ? 'Verified Active Renter' : 'Unverified'),
                const SizedBox(height: 16),
                const Text('Document Previews', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),

                // Image Preview Cards for DL and ID Proof
                Row(
                  children: [
                    Expanded(
                      child: _buildDocCard(
                        title: 'Driving License',
                        docNumber: currentCustomer.drivingLicense,
                        imgUrl: currentCustomer.dlImageUrl ??
                            'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?auto=format&fit=crop&q=80&w=800',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDocCard(
                        title: 'ID Proof (Aadhaar)',
                        docNumber: 'Verified',
                        imgUrl: currentCustomer.idProofImageUrl ??
                            'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&q=80&w=800',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Past Booking History Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Past Booking History',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.canvasLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        '${_customerBookings.length} Trips',
                        style: const TextStyle(color: AppColors.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_isLoadingBookings)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primaryCyan, strokeWidth: 2),
                    ),
                  )
                else if (_customerBookings.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.canvasLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.history_toggle_off_rounded, color: AppColors.textMuted, size: 36),
                        SizedBox(height: 8),
                        Text(
                          'No Booking History Found',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'This customer has not recorded any rental trips yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _customerBookings.length,
                    separatorBuilder: (context, index) => const Divider(color: AppColors.borderHairline, height: 20),
                    itemBuilder: (context, index) {
                      final b = _customerBookings[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              b.id,
                              style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            StatusChip.fromBookingStatus(b.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${b.vehicleName} (${b.vehicleRegNumber})',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment: ${b.paymentMode}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            Text(
                              'Total: ₹${b.totalAmount.toInt()}',
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                        if (b.pendingAmount > 0) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Pending: ₹${b.pendingAmount.toInt()}',
                                style: const TextStyle(color: AppColors.warningAmber, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Blacklist Management Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isBlacklisted ? AppColors.criticalBg.withValues(alpha: 0.5) : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isBlacklisted ? AppColors.criticalBorder : AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.block_rounded,
                      color: _isBlacklisted ? AppColors.criticalRed : AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Blacklist Customer',
                            style: TextStyle(
                              color: _isBlacklisted ? AppColors.criticalRed : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const Text(
                            'Prevent customer from placing future vehicle bookings',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isBlacklisted,
                      activeTrackColor: AppColors.criticalRed,
                      activeThumbColor: Colors.white,
                      onChanged: (val) {
                        setState(() {
                          _isBlacklisted = val;
                        });
                        _updateBlacklistStatus();
                      },
                    ),
                  ],
                ),

                if (_isBlacklisted) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.criticalBorder),
                  const SizedBox(height: 12),
                  const Text(
                    'Blacklist Reason',
                    style: TextStyle(color: AppColors.criticalRed, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Specify reason (e.g., damaged vehicle, fake ID, payment defaults)...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.canvasLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.criticalBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.criticalRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Save Reason & Status',
                    variant: ButtonVariant.destructive,
                    height: 40,
                    onPressed: _updateBlacklistStatus,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Call & Message Actions
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Call Customer',
                  icon: Icons.phone_in_talk_rounded,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${currentCustomer.name} (${currentCustomer.phone})...')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'WhatsApp Message',
                  variant: ButtonVariant.secondary,
                  icon: Icons.chat_rounded,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening WhatsApp for ${currentCustomer.phone}...')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
        ],
      ),
    ),
  ),
);
  }

  Widget _buildDocCard({
    required String title,
    required String docNumber,
    required String imgUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.canvasLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const Center(
                  child: Icon(Icons.badge_rounded, color: AppColors.primaryCyan, size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(docNumber, style: const TextStyle(color: AppColors.textMuted, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'View',
                  variant: ButtonVariant.secondary,
                  height: 28,
                  onPressed: () => _showDocumentPreview(title, docNumber, imgUrl),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: CustomButton(
                  text: 'Replace',
                  variant: ButtonVariant.secondary,
                  height: 28,
                  onPressed: () => _showReplaceDocumentSheet(title),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpi(String title, String val, {bool isWarning = false}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(color: isWarning ? AppColors.warningAmber : AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }

  Widget _infoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(val, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
