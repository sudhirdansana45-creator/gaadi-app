import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/api_service.dart';

class ForgotPinScreen extends StatefulWidget {
  final VoidCallback onBackToLogin;
  final VoidCallback onResetSuccess;

  const ForgotPinScreen({
    super.key,
    required this.onBackToLogin,
    required this.onResetSuccess,
  });

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  int _step = 1; // 1 = Enter Phone, 2 = Verify OTP & Reset PIN
  bool _isLoading = false;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;

  Timer? _resendTimer;
  int _resendCountdown = 30;
  bool _canResend = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 30;
      _canResend = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _resendCountdown--;
          });
        }
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: AppColors.criticalRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService().forgotPin(phone);
      if (mounted) {
        String msg = 'OTP sent to registered mobile successfully.';
        if (res is Map && res['data'] != null && res['data']['demo_otp'] != null) {
          msg = 'OTP sent! (Demo OTP: ${res['data']['demo_otp']})';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.primaryCyan,
          ),
        );
        setState(() {
          _step = 2;
        });
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        // Fallback for offline or testing mode
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

  Future<void> _handleResetPin() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    final pin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (otp.isEmpty || otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 4-digit verification OTP'),
          backgroundColor: AppColors.criticalRed,
        ),
      );
      return;
    }

    if (pin.isEmpty || pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security PIN must be at least 4 digits'),
          backgroundColor: AppColors.criticalRed,
        ),
      );
      return;
    }

    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New PIN and Confirm PIN do not match'),
          backgroundColor: AppColors.criticalRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService().resetPin(
        mobile: phone,
        otp: otp,
        pin: pin,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN reset successfully! You can now log in with your new PIN.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        widget.onResetSuccess();
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
              constraints: const BoxConstraints(maxWidth: 440),
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
                  // Header Row with back arrow and icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                        onPressed: _step == 2 ? () => setState(() => _step = 1) : widget.onBackToLogin,
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(Icons.lock_reset_rounded, color: AppColors.textDark, size: 26),
                        ),
                      ),
                      const SizedBox(width: 40), // Balance the row
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Title & Subtitle based on step
                  Text(
                    _step == 1 ? 'Forgot Security PIN?' : 'Set New Security PIN',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _step == 1
                        ? 'Enter your registered mobile number. We will send you an OTP to verify and reset your PIN.'
                        : 'Enter the 4-digit OTP sent to +91 ${_phoneController.text.trim()} and create your new PIN.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (_step == 1) ...[
                    // Step 1: Mobile Input
                    CustomTextField(
                      label: 'Registered Mobile Number',
                      hintText: 'Enter 10-digit number',
                      controller: _phoneController,
                      prefixText: '+91',
                      prefixIcon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Send Verification OTP',
                      icon: Icons.send_rounded,
                      isLoading: _isLoading,
                      onPressed: _handleSendOtp,
                    ),
                  ] else ...[
                    // Step 2: OTP and New PINs
                    CustomTextField(
                      label: 'Verification OTP',
                      hintText: 'Enter 4-digit OTP (e.g. 1234)',
                      controller: _otpController,
                      prefixIcon: Icons.mark_email_read_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'New 4-Digit PIN',
                      hintText: 'Enter new 4-digit PIN',
                      controller: _newPinController,
                      obscureText: _obscureNewPin,
                      prefixIcon: Icons.lock_outline_rounded,
                      keyboardType: TextInputType.number,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureNewPin = !_obscureNewPin),
                      ),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Confirm New 4-Digit PIN',
                      hintText: 'Re-enter new PIN',
                      controller: _confirmPinController,
                      obscureText: _obscureConfirmPin,
                      prefixIcon: Icons.lock_reset_rounded,
                      keyboardType: TextInputType.number,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Resend Timer Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _canResend ? "Didn't receive code?" : 'Resend OTP in ${_resendCountdown}s',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        if (_canResend)
                          GestureDetector(
                            onTap: _handleSendOtp,
                            child: const Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: AppColors.primaryCyan,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primaryCyan,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Confirm & Reset PIN',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isLoading,
                      onPressed: _handleResetPin,
                    ),
                  ],

                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: widget.onBackToLogin,
                      child: const Text(
                        'Remember PIN? Sign In',
                        style: TextStyle(
                          color: AppColors.primaryCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
