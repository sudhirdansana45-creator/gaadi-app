import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

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
  final _nameController = TextEditingController(text: 'Rajesh Sharma');
  final _businessController = TextEditingController(text: 'Rajesh Fleet Mobility');
  final _phoneController = TextEditingController(text: '9818800112');
  final _emailController = TextEditingController(text: 'rajesh@gaadimanager.in');
  final _cityController = TextEditingController(text: 'New Delhi');
  bool _isLoading = false;

  void _handleSignUp() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onSignUp();
      }
    });
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
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'City',
                          hintText: 'Delhi NCR',
                          controller: _cityController,
                          prefixIcon: Icons.location_city_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Email',
                          hintText: 'agency@gmail.com',
                          controller: _emailController,
                          prefixIcon: Icons.email_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Create Account & Start Free',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: _isLoading,
                    onPressed: _handleSignUp,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
