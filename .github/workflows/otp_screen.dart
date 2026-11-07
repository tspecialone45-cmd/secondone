import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया ६-अंकी वैध OTP प्रविष्ट करा'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).verifyOtp(otp);
    if (!mounted) return;

    if (success) {
      // Check if profile exists
      final userProfile = await ref.read(memberRepositoryProvider).getUserProfile(
            ref.read(authRepositoryProvider).currentUser!.uid,
          );

      if (!mounted) return;

      if (userProfile == null) {
        context.go('/register', extra: widget.phone);
      } else {
        if (userProfile.groupId == null) {
          if (userProfile.role.name == 'leader') {
            context.go('/create-group');
          } else {
            context.go('/join-group');
          }
        } else {
          if (userProfile.role.name == 'leader' || userProfile.role.name == 'deputy') {
            context.go('/leader-dashboard');
          } else {
            context.go('/member-dashboard');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('OTP पडताळणी'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.mark_email_read, size: 40, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'OTP प्रविष्ट करा',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '+91 ${widget.phone} या नंबरवर पाठवलेला ६-अंकी OTP टाका',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                label: '६-अंकी OTP',
                hint: 'उदा. 123456',
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 24),
              if (authState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    authState.error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              CustomButton(
                label: 'सत्यापित करा (Verify)',
                icon: Icons.check_circle_outline,
                isLoading: authState.isLoading,
                onPressed: _handleVerify,
              ),
              const SizedBox(height: 20),
              Center(
                child: _resendCountdown > 0
                    ? Text(
                        'पुन्हा OTP पाठवा ($_resendCountdown सेकंद)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : TextButton(
                        onPressed: () {
                          ref.read(authNotifierProvider.notifier).sendOtp(widget.phone);
                          _startTimer();
                        },
                        child: const Text(
                          'पुन्हा OTP पाठवा (Resend OTP)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
