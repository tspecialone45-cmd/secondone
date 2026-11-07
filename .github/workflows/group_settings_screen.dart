import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  const GroupSettingsScreen({super.key});

  @override
  ConsumerState<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _maxMembersController;
  late TextEditingController _monthlyAmountController;
  late TextEditingController _interestRateController;
  late TextEditingController _lateFeeController;

  bool _lateFeeEnabled = false;
  bool _deputyCanWrite = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final group = ref.read(currentGroupProvider).value;
    final s = group?.settings ?? GroupSettings();

    _maxMembersController = TextEditingController(text: '${s.maxMembers}');
    _monthlyAmountController = TextEditingController(text: '${s.monthlyAmount.toInt()}');
    _interestRateController = TextEditingController(text: '${s.interestRate}');
    _lateFeeController = TextEditingController(text: '${s.lateFee.toInt()}');
    _lateFeeEnabled = s.lateFeeEnabled;
    _deputyCanWrite = s.deputyCanWrite;
  }

  @override
  void dispose() {
    _maxMembersController.dispose();
    _monthlyAmountController.dispose();
    _interestRateController.dispose();
    _lateFeeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final group = ref.read(currentGroupProvider).value;
    final user = ref.read(currentUserProfileProvider).value;
    if (group == null || user == null) return;

    setState(() => _isSaving = true);

    final updatedSettings = group.settings.copyWith(
      maxMembers: int.tryParse(_maxMembersController.text.trim()) ?? 11,
      monthlyAmount: double.tryParse(_monthlyAmountController.text.trim()) ?? 100.0,
      interestRate: double.tryParse(_interestRateController.text.trim()) ?? 1.0,
      lateFee: double.tryParse(_lateFeeController.text.trim()) ?? 0.0,
      lateFeeEnabled: _lateFeeEnabled,
      deputyCanWrite: _deputyCanWrite,
    );

    await ref.read(groupNotifierProvider.notifier).updateSettings(
          groupId: group.id,
          settings: updatedSettings,
          performedBy: user.uid,
          performedByName: user.name,
        );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('गटाचे नियम व सेटिंग्स जतन झाल्या!'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(currentGroupProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('गट नियम व सेटिंग्स'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Group Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group?.name ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('गाव: ${group?.village ?? ''}', style: const TextStyle(color: AppColors.textSecondary)),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('गट कोड:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Text(group?.groupCode ?? '', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.primary)),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                                onPressed: () {
                                  if (group?.groupCode != null) {
                                    Clipboard.setData(ClipboardData(text: group!.groupCode));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कोड कॉपी केला!')));
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('नियम बदल (Rules Configuration)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'कमाल सदस्य मर्यादा (नियम: जास्तीत जास्त ११ सदस्य)',
                  controller: _maxMembersController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 2 || n > 11) return 'मर्यादा २ ते ११ दरम्यान असावी';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'दरमहा बचत रक्कम (₹)',
                  controller: _monthlyAmountController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'मासिक व्याज दर (%) - घटत्या मुद्दलावर',
                  controller: _interestRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 14),

                // Late fee toggle
                SwitchListTile(
                  value: _lateFeeEnabled,
                  activeColor: AppColors.primary,
                  title: const Text('उशिरा भरल्यास दंड लागू करा', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  onChanged: (val) => setState(() => _lateFeeEnabled = val),
                ),
                if (_lateFeeEnabled) ...[
                  CustomTextField(
                    label: 'दंड रक्कम (₹)',
                    controller: _lateFeeController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                ],

                // Deputy Write Permission Toggle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: SwitchListTile(
                    value: _deputyCanWrite,
                    activeColor: AppColors.secondary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'उपाध्यक्षांना माहिती भरण्याची व मंजूर करण्याची परवानगी',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                    subtitle: const Text(
                      'सुरू असल्यास उपाध्यक्ष सुद्धा हिशेब नोंदवू शकतात व कर्ज मंजूर करू शकतात.',
                      style: TextStyle(fontSize: 12),
                    ),
                    onChanged: (val) => setState(() => _deputyCanWrite = val),
                  ),
                ),
                const SizedBox(height: 28),

                CustomButton(
                  label: 'बदल जतन करा (Save Changes)',
                  icon: Icons.save,
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: 20),

                // Change Language link
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.push('/language'),
                    icon: const Icon(Icons.language),
                    label: const Text('ॲपची भाषा बदला (Change Language)'),
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
