import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_chip.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';
import '../../core/media/media_picker_service.dart';
import '../../core/utils/external_actions.dart';

class CustomersListScreen extends StatefulWidget {
  final Function(String route, {dynamic args}) onNavigate;

  const CustomersListScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  String _search = '';
  String _selectedFilter = 'All';
  bool _isLoading = false;
  List<Customer> _customers = [];

  final List<String> _filters = ['All', 'Verified', 'Blacklisted', 'Due'];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getCustomers();
      if (res != null && res['data'] != null) {
        final list = (res['data'] as List)
            .map((item) => Customer.fromJson(item as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _customers = list;
          });
        }
      }
    } catch (_) {
      // Offline fallback: keep current list
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showScanDlSheet(BuildContext context) {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final dlController = TextEditingController();
    final addressController = TextEditingController();
    XFile? dlImageFile;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomSheetContext, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF131722),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CD7F6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF4CD7F6), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan DL & Register Renter',
                                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Capture DL photo to verify KYC and auto-fill profile',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // DL Photo Preview & Capture Buttons
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2232),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A3854)),
                      ),
                      child: Column(
                        children: [
                          if (dlImageFile != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(dlImageFile!.path),
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF4CD7F6),
                                    side: const BorderSide(color: Color(0xFF4CD7F6)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () async {
                                    final img = await MediaPickerService.instance.captureImageWithCamera(
                                      context: bottomSheetContext,
                                      title: 'Driving License Photo',
                                    );
                                    if (img != null) {
                                      setModalState(() {
                                        dlImageFile = img;
                                        if (dlController.text.isEmpty) {
                                          dlController.text = 'DL-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
                                        }
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                                  label: const Text('Camera', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white24),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () async {
                                    final img = await MediaPickerService.instance.pickImageFromGallery(
                                      context: bottomSheetContext,
                                      title: 'Select DL from Gallery',
                                    );
                                    if (img != null) {
                                      setModalState(() {
                                        dlImageFile = img;
                                        if (dlController.text.isEmpty) {
                                          dlController.text = 'DL-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
                                        }
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.photo_library_rounded, size: 18),
                                  label: const Text('Gallery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // DL Number
                    TextField(
                      controller: dlController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Driving License Number (DL No.) *',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        hintText: 'e.g. DL-1420110012345',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF4CD7F6), size: 20),
                        filled: true,
                        fillColor: const Color(0xFF1B2232),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2A3854)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4CD7F6), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Full Name
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Customer Full Name *',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        hintText: 'e.g. Rahul Sharma',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        prefixIcon: const Icon(Icons.person_rounded, color: Colors.white70, size: 20),
                        filled: true,
                        fillColor: const Color(0xFF1B2232),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2A3854)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4CD7F6), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mobile
                    TextField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Mobile Number *',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        hintText: '10-digit mobile number',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        prefixIcon: const Icon(Icons.phone_rounded, color: Colors.white70, size: 20),
                        filled: true,
                        fillColor: const Color(0xFF1B2232),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2A3854)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4CD7F6), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Address
                    TextField(
                      controller: addressController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Address / City (Optional)',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        hintText: 'e.g. Bhubaneswar, Odisha',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        prefixIcon: const Icon(Icons.location_on_rounded, color: Colors.white70, size: 20),
                        filled: true,
                        fillColor: const Color(0xFF1B2232),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2A3854)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4CD7F6), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Save / Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CD7F6),
                          foregroundColor: const Color(0xFF003642),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = nameController.text.trim();
                                final mobile = mobileController.text.trim();
                                final dlNo = dlController.text.trim();

                                if (name.isEmpty || mobile.length < 10) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter customer full name and 10-digit mobile number.'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                try {
                                  final fields = {
                                    'name': name,
                                    'mobile': mobile,
                                    'dl_no': dlNo.isNotEmpty ? dlNo : 'DL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                    'address': addressController.text.trim(),
                                  };

                                  Map<String, File>? files;
                                  if (dlImageFile != null) {
                                    files = {'dl_front': File(dlImageFile!.path)};
                                  }

                                  await ApiService().createCustomer(
                                    fields: fields,
                                    kycFiles: files,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Customer "$name" registered successfully!'),
                                        backgroundColor: const Color(0xFF00C853),
                                      ),
                                    );
                                    _loadCustomers();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    setModalState(() => isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to save customer: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF003642)),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save & Verify Customer',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _customers.where((c) {
      // Filter category logic
      if (_selectedFilter == 'Verified' && (!c.isVerified || c.isBlacklisted)) return false;
      if (_selectedFilter == 'Blacklisted' && !c.isBlacklisted) return false;
      if (_selectedFilter == 'Due' && c.outstandingBalance <= 0) return false;

      // Search logic
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return c.name.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            c.drivingLicense.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F131D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Customers & KYC Records',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded, color: Color(0xFF4CD7F6)),
            tooltip: 'Scan DL',
            onPressed: () => _showScanDlSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Refresh',
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadCustomers,
          color: AppColors.primaryCyan,
          backgroundColor: AppColors.surfaceCard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(
                      color: AppColors.primaryCyan,
                      backgroundColor: AppColors.canvasLow,
                      minHeight: 2,
                    ),
                  ),

                // Quick Scan DL Banner Card
                GestureDetector(
                  onTap: () => _showScanDlSheet(context),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF132D3B), Color(0xFF161B26)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4CD7F6).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CD7F6).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF4CD7F6), size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Instant DL Scanner',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Scan Driving License photo & register customer instantly',
                                style: TextStyle(color: Color(0xFFB0C5DE), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CD7F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Scan DL',
                            style: TextStyle(color: Color(0xFF003844), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _search = val),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search customer by name, mobile or DL...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                          filled: true,
                          fillColor: AppColors.canvasLow,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.borderSubtle),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CustomButton(
                      text: '+ Renter',
                      width: 100,
                      height: 48,
                      onPressed: () => _showScanDlSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedFilter = filter);
                            }
                          },
                          selectedColor: AppColors.primaryCyan.withValues(alpha: 0.2),
                          backgroundColor: AppColors.surfaceCard,
                          checkmarkColor: AppColors.primaryCyan,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryCyan : AppColors.borderSubtle,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                if (list.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.people_outline_rounded, color: AppColors.primaryCyan, size: 40),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _search.isNotEmpty || _selectedFilter != 'All'
                              ? 'No customers matching filter'
                              : 'No Customers Found',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _search.isNotEmpty || _selectedFilter != 'All'
                              ? 'Try searching with another name or clearing the filter.'
                              : 'No customer profiles recorded yet. Register your first customer to manage KYC & trip history.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          text: '+ Scan DL / Add Renter',
                          width: 210,
                          height: 42,
                          onPressed: () => _showScanDlSheet(context),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final c = list[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: c.isBlacklisted
                              ? AppColors.criticalBg.withValues(alpha: 0.4)
                              : AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: c.isBlacklisted ? AppColors.criticalBorder : AppColors.borderSubtle,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: c.isBlacklisted
                                      ? AppColors.criticalBg
                                      : AppColors.surfaceHover,
                                  child: Text(
                                    c.name.isNotEmpty
                                        ? c.name.substring(0, c.name.length >= 2 ? 2 : 1).toUpperCase()
                                        : 'C',
                                    style: TextStyle(
                                      color: c.isBlacklisted
                                          ? AppColors.criticalRed
                                          : AppColors.primaryCyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Text(
                                            c.name,
                                            style: TextStyle(
                                              color: c.isBlacklisted
                                                  ? AppColors.criticalRed
                                                  : AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (c.isBlacklisted)
                                            StatusChip.blacklisted()
                                          else if (c.isVerified)
                                            StatusChip.verified(),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.badge_rounded, color: Color(0xFF4CD7F6), size: 14),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'DL: ${c.drivingLicense}',
                                              style: const TextStyle(color: Color(0xFFB0C5DE), fontSize: 11, fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${c.phone} • ${c.totalRentals} Trips • ₹${c.totalSpent.toInt()} Spent',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (c.outstandingBalance > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.warningBg,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.warningBorder),
                                        ),
                                        child: Text(
                                          'Due: ₹${c.outstandingBalance.toInt()}',
                                          style: const TextStyle(
                                            color: AppColors.warningAmber,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else
                                      const Text(
                                        'Clear Ledger',
                                        style: TextStyle(
                                          color: AppColors.successGreen,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // WhatsApp quick action
                                        InkWell(
                                          onTap: () => ExternalActions.openWhatsApp(
                                            phone: c.phone,
                                            message: 'Hello ${c.name}, greetings from Gaadi Manager!',
                                            context: context,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF25D366).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 16),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Call quick action
                                        InkWell(
                                          onTap: () => ExternalActions.makePhoneCall(c.phone),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4CD7F6).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.phone_rounded, color: Color(0xFF4CD7F6), size: 16),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        CustomButton(
                                          text: 'Profile',
                                          variant: ButtonVariant.secondary,
                                          width: 65,
                                          height: 30,
                                          onPressed: () => widget.onNavigate('customer_profile', args: c),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (c.isBlacklisted && c.blacklistReason != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.criticalBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.criticalBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: AppColors.criticalRed, size: 14),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Reason: ${c.blacklistReason}',
                                        style: const TextStyle(
                                          color: AppColors.criticalRed,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
              ],
            ),
          ),
        ),
      ),
    );
  }
}
