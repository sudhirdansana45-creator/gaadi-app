import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/api_service.dart';
import '../../services/api_client.dart';

class PrivacyDataScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const PrivacyDataScreen({
    super.key,
    required this.onBack,
    required this.onLogout,
  });

  @override
  State<PrivacyDataScreen> createState() => _PrivacyDataScreenState();
}

class _PrivacyDataScreenState extends State<PrivacyDataScreen> {
  bool _isLoading = true;
  String _policyVersion = '1.0.0';
  String _effectiveDate = '2026-10-30';
  bool _whatsappConsent = true;
  bool _marketingConsent = false;
  Map<String, dynamic> _grievanceOfficer = {
    'name': 'Compliance & Grievance Officer',
    'email': 'grievance@ersudhir.cloud',
    'phone': '+91 98765 43210',
    'address': 'Gaadi Manager Compliance Cell, Bhubaneswar, Odisha - 751024',
  };

  @override
  void initState() {
    super.initState();
    _loadComplianceData();
  }

  Future<void> _loadComplianceData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getLatestPolicy();
      if (res is Map && res['data'] is Map) {
        final policy = res['data']['policy'];
        if (policy is Map) {
          _policyVersion = policy['version']?.toString() ?? '1.0.0';
          _effectiveDate = policy['effective_date']?.toString() ?? '2026-10-30';
        }
        final officer = res['data']['grievance_officer'];
        if (officer is Map<String, dynamic>) {
          _grievanceOfficer = officer;
        }
      }

      final consentsRes = await ApiService().getConsents();
      if (consentsRes is Map && consentsRes['data'] is List) {
        final list = consentsRes['data'] as List;
        for (final item in list) {
          if (item is Map) {
            final purpose = item['purpose']?.toString();
            final hasConsented = item['has_consented'] == true;
            if (purpose == 'whatsapp_automation') {
              _whatsappConsent = hasConsented;
            } else if (purpose == 'marketing_product_offers') {
              _marketingConsent = hasConsented;
            }
          }
        }
      }
    } catch (_) {
      // Fallback to defaults
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleConsent(String purpose, bool value) async {
    setState(() {
      if (purpose == 'whatsapp_automation') _whatsappConsent = value;
      if (purpose == 'marketing_product_offers') _marketingConsent = value;
    });

    try {
      if (value) {
        await ApiService().recordConsent(
          purpose: purpose,
          policyVersion: _policyVersion,
          hasConsented: true,
        );
      } else {
        await ApiService().withdrawConsent(purpose);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Consent granted.' : 'Consent withdrawn successfully.'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Rollback on error
      setState(() {
        if (purpose == 'whatsapp_automation') _whatsappConsent = !value;
        if (purpose == 'marketing_product_offers') _marketingConsent = !value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update consent: $e'),
            backgroundColor: AppColors.criticalRed,
          ),
        );
      }
    }
  }

  Future<void> _handleExportData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await ApiService().exportMyData();
      if (mounted) Navigator.pop(context); // Close loading

      if (res is Map && res['data'] is Map) {
        _showExportSummaryModal(res['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Invalid export response format');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: AppColors.criticalRed,
          ),
        );
      }
    }
  }

  void _showExportSummaryModal(Map<String, dynamic> exportData) {
    final user = exportData['user'] as Map<String, dynamic>? ?? {};
    final summary = exportData['data_summary'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceSheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.download_done_rounded, color: AppColors.primaryCyan, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Your Personal Data Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Right of Access under DPDP Act 2023 Section 11',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const Divider(height: 24),
                  _infoRow('Operator Name', user['name']?.toString() ?? '-'),
                  _infoRow('Registered Mobile', user['mobile'] != null ? '+91 ${user['mobile']}' : '-'),
                  _infoRow('Email', user['email']?.toString() ?? 'Not provided'),
                  _infoRow('Business Name', user['business_name']?.toString() ?? '-'),
                  _infoRow('City', user['city']?.toString() ?? '-'),
                  _infoRow('Account Created', user['created_at']?.toString() ?? '-'),
                  const SizedBox(height: 16),
                  const Text('Entity Records Retained', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        _summaryCountRow('Fleet Vehicles', summary['total_vehicles']?.toString() ?? '0'),
                        _summaryCountRow('Customer Profiles', summary['total_customers']?.toString() ?? '0'),
                        _summaryCountRow('Rental Bookings', summary['total_bookings']?.toString() ?? '0'),
                        _summaryCountRow('Investor Partners', summary['total_partners']?.toString() ?? '0'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Close Summary',
                    variant: ButtonVariant.secondary,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCorrectionModal() {
    final entityCtrl = TextEditingController(text: 'Operator Business Profile');
    final descCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceSheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Request Data Correction',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Right of Correction & Updating under DPDP Act 2023 Sec 12',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const Divider(height: 20),
                  CustomTextField(
                    label: 'Target Record / Entity',
                    controller: entityCtrl,
                    hintText: 'e.g. Phone number update or Business GSTIN',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Details of Correction Needed',
                    controller: descCtrl,
                    hintText: 'Describe inaccurate data and the corrected information...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Submit Correction Request',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      if (descCtrl.text.trim().isEmpty) return;
                      setModalState(() => isSubmitting = true);
                      try {
                        await ApiService().submitCorrectionRequest(
                          targetEntity: 'user_profile',
                          corrections: {'description': descCtrl.text.trim()},
                          reason: entityCtrl.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Correction request logged. Statutory resolution within 30 days.'),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.criticalRed),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showGrievanceModal() {
    final user = ApiClient().currentUser;
    final nameCtrl = TextEditingController(text: user?['name']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: user?['email']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: user?['mobile']?.toString() ?? '');
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceSheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'DPDP Grievance Redressal (Sec 13)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Mandatory 30-day statutory response by Data Protection Officer',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const Divider(height: 20),
                  CustomTextField(label: 'Your Name', hintText: 'Enter your name', controller: nameCtrl),
                  const SizedBox(height: 10),
                  CustomTextField(label: 'Email', hintText: 'Enter your email address', controller: emailCtrl),
                  const SizedBox(height: 10),
                  CustomTextField(label: 'Mobile', hintText: 'Enter 10-digit mobile number', controller: phoneCtrl),
                  const SizedBox(height: 10),
                  CustomTextField(label: 'Subject of Grievance', controller: subjectCtrl, hintText: 'e.g. Unauthorized marketing call'),
                  const SizedBox(height: 10),
                  CustomTextField(label: 'Detailed Description', controller: descCtrl, maxLines: 3, hintText: 'Provide facts, dates, and grievance details...'),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Lodge Official Grievance',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      if (subjectCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) return;
                      setModalState(() => isSubmitting = true);
                      try {
                        final res = await ApiService().submitGrievance(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          subject: subjectCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                        );
                        String ticketNo = '';
                        if (res is Map && res['data'] is Map) {
                          ticketNo = res['data']['ticket_no']?.toString() ?? '';
                        }
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Grievance logged! Ticket: $ticketNo. Resolution within 30 days.'),
                              backgroundColor: AppColors.successGreen,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.criticalRed),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountFlow() {
    final reasonCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.criticalRed, width: 1.5),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.criticalRed, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Delete Account (Erasure)',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.criticalRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '⚠️ 7-Day Cooling Period Notice:\n'
                      'Upon submitting this request, your account will enter a mandatory 7-day cooling period. During this time, you may cancel deletion by logging back in.\n\n'
                      'After 7 days, all KYC documents, customer profiles, and vehicle images will be permanently erased.\n\n'
                      'GST Invoices and ledger records will be retained in anonymised format for 72 months as legally required under CGST Act Section 36.',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 11, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Reason for Deletion (Optional)',
                    controller: reasonCtrl,
                    hintText: 'e.g. Closing rental business operations',
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.all(16),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      variant: ButtonVariant.ghost,
                      height: 42,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: 'Delete Account',
                      variant: ButtonVariant.destructive,
                      isLoading: isSubmitting,
                      height: 42,
                      onPressed: () async {
                        setDialogState(() => isSubmitting = true);
                        try {
                          await ApiService().deleteAccount(reasonCtrl.text.trim());
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account deletion scheduled. Cooling period active for 7 days.'),
                                backgroundColor: AppColors.criticalRed,
                                duration: Duration(seconds: 4),
                              ),
                            );
                            widget.onLogout();
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.criticalRed),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _summaryCountRow(String label, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(count, style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy & Data Governance'),
        backgroundColor: AppColors.surfaceCard,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Policy Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: AppColors.primaryCyan, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DPDP Policy Version $_policyVersion',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                              ),
                              Text(
                                'Effective: $_effectiveDate • DPDP Act 2023 Compliant',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Itemised Consent Section
                  const Text(
                    'Itemised Affirmative Consents',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15),
                  ),
                  const Text(
                    'Under Section 6 DPDP Act, you have the right to withdraw specific consents at any time.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        const SwitchListTile(
                          value: true,
                          onChanged: null, // Mandatory
                          title: Text('Account & Fleet Operations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          subtitle: Text('Required for vehicle rentals, GST billing, and app functionality', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          secondary: Icon(Icons.car_rental_rounded, color: AppColors.primaryCyan),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: _whatsappConsent,
                          activeThumbColor: AppColors.primaryCyan,
                          onChanged: (val) => _toggleConsent('whatsapp_automation', val),
                          title: const Text('WhatsApp Reminders & Booking Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          subtitle: const Text('Send automated pickup, return, and payment receipts via WhatsApp', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          secondary: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.successGreen),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: _marketingConsent,
                          activeThumbColor: AppColors.primaryCyan,
                          onChanged: (val) => _toggleConsent('marketing_product_offers', val),
                          title: const Text('Product Offers & Commercial Updates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          subtitle: const Text('Receive GPS tracker discounts, accessory offers, and new features', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          secondary: const Icon(Icons.campaign_outlined, color: AppColors.warningAmber),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Data Subject Rights
                  const Text(
                    'Data Subject Rights (DPDP Act Sec 11-14)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.download_rounded, color: AppColors.primaryCyan),
                          title: const Text('Download My Data Summary (Sec 11)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          subtitle: const Text('Access itemised summary of personal data & fleet records held', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                          onTap: _handleExportData,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.edit_note_rounded, color: AppColors.primaryCyan),
                          title: const Text('Request Data Correction (Sec 12)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          subtitle: const Text('Submit correction or rectification request for inaccurate records', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                          onTap: _showCorrectionModal,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.support_agent_rounded, color: AppColors.primaryCyan),
                          title: const Text('Lodge Grievance with DPO (Sec 13)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          subtitle: const Text('Submit official grievance with statutory 30-day resolution timeline', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                          onTap: _showGrievanceModal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grievance Officer Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppColors.primaryCyan, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Statutory Grievance Officer (DPDP Sec 13)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _infoRow('Officer Name', _grievanceOfficer['name']?.toString() ?? 'Compliance Officer'),
                        _infoRow('Email', _grievanceOfficer['email']?.toString() ?? 'grievance@ersudhir.cloud'),
                        _infoRow('Phone', _grievanceOfficer['phone']?.toString() ?? '+91 98765 43210'),
                        const SizedBox(height: 4),
                        Text(
                          'Address: ${_grievanceOfficer['address'] ?? 'Bhubaneswar, Odisha - 751024'}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Google Play Account Erasure Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.criticalRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.criticalRed.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.delete_forever_rounded, color: AppColors.criticalRed, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Delete Account & Erasure (DPDP Sec 12(3))',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.criticalRed, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Request permanent erasure of your account, KYC records, and vehicle data under Google Play Store and DPDP policies. A 7-day cooling-off window is provided.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Initiate Account Deletion',
                          variant: ButtonVariant.destructive,
                          height: 38,
                          onPressed: _showDeleteAccountFlow,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
