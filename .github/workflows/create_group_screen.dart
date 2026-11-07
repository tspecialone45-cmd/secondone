import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _villageController = TextEditingController();
  final _maxMembersController = TextEditingController(text: '11');
  final _monthlyAmountController = TextEditingController(text: '100');
  final _interestRateController = TextEditingController(text: '1.0');
  final _lateFeeController = TextEditingController(text: '10');

  DateTime _startDate = DateTime.now();
  bool _enableLateFee = false;
  bool _deputyCanWrite = true;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
    _maxMembersController.dispose();
    _monthlyAmountController.dispose();
    _interestRateController.dispose();
    _lateFeeController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _handleCreateGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया प्रथम लॉगिन करा.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isCreating = true);

    final settings = GroupSettings(
      maxMembers: int.tryParse(_maxMembersController.text.trim()) ?? 11,
      monthlyAmount: double.tryParse(_monthlyAmountController.text.trim()) ?? 100.0,
      interestRate: double.tryParse(_interestRateController.text.trim()) ?? 1.0,
      lateFee: double.tryParse(_lateFeeController.text.trim()) ?? 0.0,
      lateFeeEnabled: _enableLateFee,
      deputyCanWrite: _deputyCanWrite,
    );

    final group = await ref.read(groupNotifierProvider.notifier).createGroup(
          name: _nameController.text.trim(),
          village: _villageController.text.trim(),
          startDate: _startDate,
          leaderUid: user.uid,
          leaderName: user.name,
          leaderPhone: user.phone,
          settings: settings,
        );

    setState(() => _isCreating = false);

    if (group != null && mounted) {
      _showSuccessDialog(group.groupCode);
    }
  }

  void _showSuccessDialog(String groupCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primary, size: 28),
            SizedBox(width: 8),
            Text('गट तयार झाला!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'आपला बचत गट यशस्वीपणे तयार करण्यात आला आहे. नवीन सदस्यांना जोडण्यासाठी खालील गट कोड द्या:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Center(
                child: Text(
                  groupCode,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: groupCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('गट कोड कॉपी केला!')),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('कोड कॉपी करा'),
            ),
          ],
        ),
        actions: [
          CustomButton(
            label: 'डॅशबोर्डवर जा',
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/leader-dashboard');
            },
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
        title: const Text('नवीन गट तयार करा'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'बचत गटाचे तपशील आणि नियम',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'बचत गटाचे नाव',
                  hint: 'उदा. सावित्रीबाई फुले महिला बचत गट',
                  controller: _nameController,
                  prefixIcon: Icons.group_work,
                  validator: (v) => Validators.validateRequired(v, 'गटाचे नाव'),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'गाव / ठिकाण',
                  hint: 'उदा. वडगाव शेरी, ता. हवेली',
                  controller: _villageController,
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) => Validators.validateRequired(v, 'गाव'),
                ),
                const SizedBox(height: 16),

                // Start Date Picker
                InkWell(
                  onTap: _pickStartDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('गटाचा आरंभ दिनांक', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(_startDate.toFormattedDate(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Icon(Icons.calendar_today, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'नियम व अटी (बदलता येण्याजोगे)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 14),

                // Max Members
                CustomTextField(
                  label: 'जास्तीत जास्त सदस्य मर्यादा (नियम: जास्तीत जास्त ११)',
                  hint: '11',
                  controller: _maxMembersController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.people_outline,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 2 || n > 11) {
                      return 'सदस्य संख्या २ ते ११ दरम्यान असावी';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Monthly Saving Amount
                CustomTextField(
                  label: 'दरमहा बचत रक्कम (₹)',
                  hint: '100',
                  controller: _monthlyAmountController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.currency_rupee,
                  validator: Validators.validateAmount,
                ),
                const SizedBox(height: 16),

                // Interest Rate
                CustomTextField(
                  label: 'मासिक व्याज दर (% - नियम: १% प्रति महिना)',
                  hint: '1.0',
                  controller: _interestRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.percent,
                ),
                const SizedBox(height: 16),

                // Late fee toggle
                SwitchListTile(
                  value: _enableLateFee,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('उशिरा भरल्यास दंड / लेट फी लागू करा', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  onChanged: (val) => setState(() => _enableLateFee = val),
                ),
                if (_enableLateFee) ...[
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: 'दंड रक्कम (₹)',
                    hint: '10',
                    controller: _lateFeeController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.warning_amber_rounded,
                  ),
                ],
                const SizedBox(height: 8),

                // Deputy Write Permission
                SwitchListTile(
                  value: _deputyCanWrite,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('उपाध्यक्षांना हिशेब नोंदवण्याची परवानगी द्या', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('सुरू ठेवल्यास उपाध्यक्ष सुद्धा बचत, कर्ज व हजेरी नोंदवू शकतात.', style: TextStyle(fontSize: 12)),
                  onChanged: (val) => setState(() => _deputyCanWrite = val),
                ),
                const SizedBox(height: 28),

                CustomButton(
                  label: 'गट तयार करा (Create Group)',
                  icon: Icons.check,
                  isLoading: _isCreating,
                  backgroundColor: AppColors.secondary,
                  onPressed: _handleCreateGroup,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
