import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  UserRole _selectedRole = UserRole.member;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authNotifierProvider.notifier).setRole(_selectedRole);
    ref.read(authNotifierProvider.notifier).sendOtp(_phoneController.text.trim());
    context.push('/otp', extra: _phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'म',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'महिला बचत गट',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'लॉगिन करण्यासाठी आपली भूमिका निवडा',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // Role Selection Cards
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedRole = UserRole.leader;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == UserRole.leader
                                ? AppColors.secondary.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedRole == UserRole.leader
                                  ? AppColors.secondary
                                  : AppColors.border,
                              width: _selectedRole == UserRole.leader ? 2.5 : 1.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                size: 36,
                                color: _selectedRole == UserRole.leader
                                    ? AppColors.secondary
                                    : AppColors.textLight,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'अध्यक्ष\n(Leader)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedRole == UserRole.leader
                                      ? AppColors.secondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedRole = UserRole.member;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == UserRole.member
                                ? AppColors.primary.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedRole == UserRole.member
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: _selectedRole == UserRole.member ? 2.5 : 1.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people,
                                size: 36,
                                color: _selectedRole == UserRole.member
                                    ? AppColors.primary
                                    : AppColors.textLight,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'सदस्य\n(Member)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedRole == UserRole.member
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Phone Input Field
                CustomTextField(
                  label: 'मोबाईल नंबर (Mobile Number)',
                  hint: '१०-अंकी मोबाईल नंबर टाका',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  prefixIcon: Icons.phone_android,
                  validator: Validators.validatePhone,
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
                  label: 'OTP पाठवा (Send OTP)',
                  icon: Icons.send,
                  isLoading: authState.isLoading,
                  backgroundColor: _selectedRole == UserRole.leader
                      ? AppColors.secondary
                      : AppColors.primary,
                  onPressed: _handleSendOtp,
                ),
                const SizedBox(height: 20),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'नवीन आहात का? ',
                      style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                    ),
                    InkWell(
                      onTap: () {
                        context.push('/register');
                      },
                      child: const Text(
                        'येथे नोंदणी करा',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Language switch button
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.push('/language'),
                    icon: const Icon(Icons.language, size: 18),
                    label: const Text('भाषा बदला (Change Language)'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
