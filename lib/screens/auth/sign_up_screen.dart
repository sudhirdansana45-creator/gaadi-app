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

    setState(() => _isLoading = true);

    try {
      final res = await ApiService().register(
        name: name,
        mobile: mobile,
        password: pin.isNotEmpty ? pin : '1234',
        email: email.isNotEmpty ? email : null,
        businessName: business.isNotEmpty ? business : null,
        city: city.isNotEmpty ? city : null,
      );

      if (res is Map<String, dynamic> && res['token'] != null) {
        await ApiClient().setToken(res['token'].toString());
      }

      if (mounted) {
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
                    label: 'Create 4-Digit Security PIN',
                    hintText: 'Enter 4-digit PIN for login (e.g. 1234)',
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
                  const SizedBox(height: 24),
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
