import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/api_service.dart';
import '../../services/api_client.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback onSignUp;
  final VoidCallback onLogin;

  const SignUpScreen({
    super.key,
    required this.onSignUp,
    required this.onLogin,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _isAge18Plus = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _showLegalModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceSheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
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
                  const Text(
                    'Terms of Service & Data Processing Agreement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version 1.0.0 • Under Digital Personal Data Protection Act 2023',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const Divider(height: 24),
                  const Text(
                    '1. Data Processing Agreement (DPA)\n'
                    'When you manage customer bookings, driving licences, and personal details on Gaadi Manager, you act as the Data Fiduciary under the DPDP Act 2023. Gaadi Manager acts as your Data Processor. We process customer data strictly on your documented instructions and implement ISO/CERT-In grade technical safeguards.\n\n'
                    '2. Vehicle Fleet & Statutory Verification\n'
                    'You agree to verify that customers hold valid, unexpired Driving Licences under Section 3 of the Motor Vehicles Act 1988 before dispatching vehicles.\n\n'
                    '3. Data Retention & GST Compliance\n'
                    'Tax invoices, SAC 9973 rental billing, and transaction records will be retained for at least 72 months (approx 6-8 years) as mandated under Section 36 of the Central Goods and Services Tax Act 2017.\n\n'
                    '4. Grievance Officer & Contact\n'
                    'For inquiries or DPDP rights requests, contact: grievance@ersudhir.cloud / +91 98765 43210.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'I Understand & Agree',
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _acceptedTerms = true);
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

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final mobile = _phoneController.text.trim();
    final business = _businessController.text.trim();
    final city = _cityController.text.trim();
    final email = _emailController.text.trim();
    final pin = _pinController.text.trim();

    if (name.isEmpty || mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name and mobile number'),
          backgroundColor: AppColors.criticalRed,
        ),
      );
      return;
    }

    if (mobile.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: AppColors.criticalRed,
        ),
      );
      return;
    }

    if (pin.isEmpty || pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a secure 4-digit PIN for your account'),
          backgroundColor: AppColors.criticalRed,
        ),
      );
      return;
    }

    if (!_isAge18Plus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must confirm you are 18+ to register under DPDP Act 2023.'),
          backgroundColor: AppColors.criticalRed,
        ),
      );
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service & Data Processing Agreement.'),
          backgroundColor: AppColors.criticalRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService().register(
        name: name,
        mobile: mobile,
        password: pin,
        email: email.isNotEmpty ? email : null,
        businessName: business.isNotEmpty ? business : null,
        city: city.isNotEmpty ? city : null,
      );

      String? token;
      if (res is Map<String, dynamic>) {
        if (res['token'] != null) {
          token = res['token'].toString();
        } else if (res['data'] is Map && res['data']['token'] != null) {
          token = res['data']['token'].toString();
        }
        final dynamic userObj = res['user'] ?? (res['data'] is Map ? res['data']['user'] : null);
        if (userObj is Map<String, dynamic>) {
          await ApiClient().setUser(userObj);
        }
      }

      if (token != null) {
        await ApiClient().setToken(token);
        try {
          await ApiService().acceptPolicy('1.0.0');
          await ApiService().recordConsent(
            purpose: 'account_service',
            policyVersion: '1.0.0',
            hasConsented: true,
          );
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Welcome to Gaadi Manager.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        widget.onSignUp();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')),
            backgroundColor: AppColors.criticalRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 32,
                    offset: Offset(0, 12),
                  )
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.directions_car_filled_rounded, color: AppColors.textDark, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gaadi Manager',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Operator Registration',
                            style: TextStyle(color: AppColors.primaryCyan, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create Business Account',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Setup your fleet ledger and vehicle rental business in 2 minutes',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'Owner / Operator Name',
                    hintText: 'e.g. Rajesh Sharma',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Business / Agency Name',
                    hintText: 'e.g. Speedo Car Rentals',
                    controller: _businessController,
                    prefixIcon: Icons.business_rounded,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Mobile Number (WhatsApp)',
                    hintText: '10-digit mobile number',
                    controller: _phoneController,
                    prefixText: '+91',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Operating City',
                    hintText: 'e.g. Mumbai, Delhi NCR, Bhubaneswar',
                    controller: _cityController,
                    prefixIcon: Icons.location_city_rounded,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Email Address (Optional)',
                    hintText: 'e.g. agency@gmail.com',
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Create 4-Digit Security PIN *',
                    hintText: 'Enter 4-digit PIN for login',
                    controller: _pinController,
                    obscureText: _obscurePin,
                    prefixIcon: Icons.lock_outline_rounded,
                    keyboardType: TextInputType.number,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Age Verification (DPDP Act Sec 9)
                  InkWell(
                    onTap: () => setState(() => _isAge18Plus = !_isAge18Plus),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _isAge18Plus,
                              activeColor: AppColors.primaryCyan,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) => setState(() => _isAge18Plus = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'I confirm I am 18 years of age or older (Mandatory under DPDP Act 2023 Sec 9).',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Terms of Service & DPA Agreement
                  InkWell(
                    onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _acceptedTerms,
                              activeColor: AppColors.primaryCyan,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Wrap(
                              children: [
                                const Text(
                                  'I agree to the ',
                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                                ),
                                GestureDetector(
                                  onTap: _showLegalModal,
                                  child: const Text(
                                    'Terms of Service, DPA, & Privacy Policy',
                                    style: TextStyle(
                                      color: AppColors.primaryCyan,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const Text(
                                  ' as Data Fiduciary under DPDP Act.',
                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Create Account & Start Free',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: _isLoading,
                    onPressed: _handleSignUp,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Already registered? ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: widget.onLogin,
                        child: const Text(
                          'Sign In Here',
                          style: TextStyle(
                            color: AppColors.primaryCyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
