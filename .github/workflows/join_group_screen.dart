import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _codeController = TextEditingController();
  GroupModel? _searchedGroup;
  bool _isSearching = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया वैध ६-अंकी गट कोड टाका'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _searchedGroup = null;
    });

    try {
      final group = await ref.read(groupRepositoryProvider).getGroupByCode(code);
      setState(() {
        _searchedGroup = group;
        _isSearching = false;
      });

      if (group == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('हा कोड असलेला गट सापडला नाही.'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleSendRequest() async {
    if (_searchedGroup == null) return;

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    if (_searchedGroup!.memberCount >= _searchedGroup!.settings.maxMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('या गटात आधीच ११ सदस्य पूर्ण झाले आहेत. नवीन सदस्य जोडता येणार नाही.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref.read(groupNotifierProvider.notifier).joinGroupByCode(
          groupCode: _searchedGroup!.groupCode,
          userId: user.uid,
          userName: user.name,
          userPhone: user.phone,
        );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read, color: AppColors.primary, size: 28),
              SizedBox(width: 8),
              Text('विनंती पाठवली!'),
            ],
          ),
          content: const Text(
            'आपली बचत गटात सामील होण्याची विनंती अध्यक्षांकडे पाठवण्यात आली आहे. अध्यक्षांनी मंजूर केल्यानंतर आपण गटात सामील व्हाल.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            CustomButton(
              label: 'ठीक आहे',
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/member-dashboard');
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('गटात सामील व्हा (Join Group)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Text(
                'गट कोड प्रविष्ट करा',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'आपल्या बचत गट अध्यक्षांकडून मिळालेला ६-अक्षरी कोड येथे प्रविष्ट करा.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                label: 'गट कोड (६ अक्षरे)',
                hint: 'उदा. ABC123',
                controller: _codeController,
                maxLength: 6,
                prefixIcon: Icons.qr_code,
                validator: Validators.validateGroupCode,
              ),
              const SizedBox(height: 16),

              CustomButton(
                label: 'गट शोधा (Search Group)',
                icon: Icons.search,
                isLoading: _isSearching,
                onPressed: _handleSearch,
              ),
              const SizedBox(height: 28),

              // Group Preview Card
              if (_searchedGroup != null) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.groups, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _searchedGroup!.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _searchedGroup!.village,
                                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('सदस्य संख्या:', style: TextStyle(color: AppColors.textSecondary)),
                          Text(
                            '${_searchedGroup!.memberCount} / ${_searchedGroup!.settings.maxMembers} (मर्यादा)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('मासिक बचत:', style: TextStyle(color: AppColors.textSecondary)),
                          Text(
                            '₹${_searchedGroup!.settings.monthlyAmount.toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('मासिक कर्ज व्याज:', style: TextStyle(color: AppColors.textSecondary)),
                          Text(
                            '${_searchedGroup!.settings.interestRate}% प्रति महिना',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        label: 'सामील होण्यासाठी विनंती पाठवा',
                        icon: Icons.send,
                        isLoading: _isSubmitting,
                        onPressed: _handleSendRequest,
                      ),
                    ],
                  ),
                ),
              ],

              if (groupState.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    groupState.error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
