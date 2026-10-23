import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../models/mock_models.dart';
import '../../data/mock_data.dart';

class CustomerProfileScreen extends StatefulWidget {
  final Customer customer;
  final VoidCallback onBack;

  const CustomerProfileScreen({
    super.key,
    required this.customer,
    required this.onBack,
  });

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  late bool _isBlacklisted;
  late TextEditingController _reasonController;
  late List<Booking> _customerBookings;

  @override
  void initState() {
    super.initState();
    _isBlacklisted = widget.customer.isBlacklisted;
    _reasonController = TextEditingController(text: widget.customer.blacklistReason ?? '');

    // Get bookings for this customer or provide realistic fallback mock bookings
    final matches = MockData.bookings.where((b) {
      return b.customerName.toLowerCase() == widget.customer.name.toLowerCase() ||
          b.customerPhone == widget.customer.phone;
    }).toList();

    if (matches.isNotEmpty) {
      _customerBookings = matches;
    } else {
      // Fallback mock bookings so history is visible for all test customers
      _customerBookings = [
        Booking(
          id: 'BK-1052',
          customerName: widget.customer.name,
          customerPhone: widget.customer.phone,
          vehicleName: 'Mahindra Thar 4x4',
          vehicleRegNumber: 'DL 01 AB 1234',
          startDate: DateTime.now().subtract(const Duration(days: 15)),
          endDate: DateTime.now().subtract(const Duration(days: 12)),
          totalAmount: 10500.0,
          advancePaid: 10500.0,
          pendingAmount: 0.0,
          securityDeposit: 5000.0,
          status: BookingStatus.completed,
          startOdometer: 23800,
          endOdometer: 24200,
          paymentMode: 'UPI (GPay)',
          kycDocType: 'Driving License',
          kycDocNumber: widget.customer.drivingLicense,
        ),
        Booking(
          id: 'BK-0994',
          customerName: widget.customer.name,
          customerPhone: widget.customer.phone,
          vehicleName: 'Hyundai Creta SX',
          vehicleRegNumber: 'DL 03 CD 5678',
          startDate: DateTime.now().subtract(const Duration(days: 45)),
          endDate: DateTime.now().subtract(const Duration(days: 43)),
          totalAmount: 5600.0,
          advancePaid: 5600.0,
          pendingAmount: 0.0,
          securityDeposit: 3000.0,
          status: BookingStatus.completed,
          startOdometer: 16500,
          endOdometer: 16900,
          paymentMode: 'Card Swipe',
          kycDocType: 'Aadhaar Card',
          kycDocNumber: '4829 **** 1092',
        ),
      ];
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
    setState(() {
      widget.customer.isBlacklisted = _isBlacklisted;
      widget.customer.blacklistReason = _isBlacklisted ? _reasonController.text : null;
    });

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
    return SingleChildScrollView(
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
                        widget.customer.name.substring(0, 2).toUpperCase(),
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
                                widget.customer.name,
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
                                  widget.customer.rating,
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
                              else if (widget.customer.isVerified)
                                StatusChip.verified(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(widget.customer.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Text(widget.customer.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
                    _kpi('Total Trips', '${widget.customer.totalRentals}'),
                    _kpi('Lifetime Spent', '₹${widget.customer.totalSpent.toInt()}'),
                    _kpi('Balance Due', '₹${widget.customer.outstandingBalance.toInt()}', isWarning: widget.customer.outstandingBalance > 0),
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
                _infoRow('Driving License:', widget.customer.drivingLicense),
                _infoRow('Registered Address:', widget.customer.address),
                _infoRow('Verification Status:', widget.customer.isVerified ? 'Verified Active Renter' : 'Unverified'),
                const SizedBox(height: 16),
                const Text('Document Previews', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),

                // Image Preview Cards for DL and ID Proof
                Row(
                  children: [
                    Expanded(
                      child: _buildDocCard(
                        title: 'Driving License',
                        docNumber: widget.customer.drivingLicense,
                        imgUrl: widget.customer.dlImageUrl ??
                            'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?auto=format&fit=crop&q=80&w=800',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDocCard(
                        title: 'ID Proof (Aadhaar)',
                        docNumber: '4829 **** 1092',
                        imgUrl: widget.customer.idProofImageUrl ??
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
                      SnackBar(content: Text('Calling ${widget.customer.name} (${widget.customer.phone})...')),
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
                      SnackBar(content: Text('Opening WhatsApp for ${widget.customer.phone}...')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
        ],
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
