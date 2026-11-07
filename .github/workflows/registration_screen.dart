import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/aadhaar_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final String? initialPhone;

  const RegistrationScreen({super.key, this.initialPhone});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villageController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _storageRepository = StorageRepository();

  File? _profileImage;
  UserRole _role = UserRole.member;
  bool _aadhaarConsentGiven = false;
  bool _isLoading = false;

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await _storageRepository.pickImage(source);
    if (file != null) {
      setState(() {
        _profileImage = file;
      });
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('प्रोफाइल फोटो निवडा (पर्यायी)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickPhoto(ImageSource.camera);
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(height: 8),
                        const Text('कॅमेरा (Camera)'),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickPhoto(ImageSource.gallery);
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.secondary.withOpacity(0.12),
                          child: const Icon(Icons.photo_library, color: AppColors.secondary, size: 28),
                        ),
                        const SizedBox(height: 8),
                        const Text('गॅलरी (Gallery)'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null) {
      _phoneController.text = widget.initialPhone!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_aadhaarConsentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया आधार संमती चेकबॉक्स निवडा.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentAuthUser = ref.read(authRepositoryProvider).currentUser;
      final uid = currentAuthUser?.uid ?? DateTime.now().millisecondsSinceEpoch.toString();

      final fullAadhaar = _aadhaarController.text.trim();
      final last4 = AadhaarUtils.extractLast4(fullAadhaar);
      final encryptedAadhaar = AadhaarUtils.encryptAadhaar(fullAadhaar);
      final currentLang = ref.read(localeProvider).languageCode;

      String? photoUrl;
      if (_profileImage != null) {
        try {
          photoUrl = await _storageRepository.uploadProfilePhoto(uid: uid, imageFile: _profileImage!);
        } catch (_) {}
      }

      final newUser = UserModel(
        uid: uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        village: _villageController.text.trim(),
        aadhaarLast4: last4,
        aadhaarEncrypted: encryptedAadhaar,
        role: _role,
        language: currentLang,
        profilePhotoUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      await ref.read(authNotifierProvider.notifier).registerProfile(newUser);

      if (!mounted) return;

      if (_role == UserRole.leader) {
        context.go('/create-group');
      } else {
        context.go('/join-group');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('नोंदणी करताना त्रुटी आली: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('नवीन नोंदणी (Registration)'),
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
                  'आपली संपूर्ण माहिती भरा',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'माहिती अचूक असावी जेणेकरून बचत गटाचे हिशेब पारदर्शक राहतील.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Role Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _role = UserRole.member),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _role == UserRole.member ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _role == UserRole.member
                                  ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'सदस्य (Member)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _role == UserRole.member
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _role = UserRole.leader),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _role == UserRole.leader ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _role == UserRole.leader
                                  ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'अध्यक्ष (Leader)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _role == UserRole.leader
                                      ? AppColors.secondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Photo Picker Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? const Icon(Icons.person, size: 52, color: AppColors.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _showImagePickerSheet,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'प्रोफाइल फोटो निवडा (पर्यायी)',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  label: 'पूर्ण नाव (आधार कार्डानुसार)',
                  hint: 'उदा. सुनंदा विलास पाटील',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => Validators.validateRequired(v, 'पूर्ण नाव'),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'मोबाईल नंबर',
                  hint: '१०-अंकी मोबाईल नंबर',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  prefixIcon: Icons.phone_android,
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'गाव / पत्ता (Village / Address)',
                  hint: 'उदा. मु. पो. शिरूर, ता. हवेली, जि. पुणे',
                  controller: _villageController,
                  prefixIcon: Icons.home_outlined,
                  validator: (v) => Validators.validateRequired(v, 'गाव/पत्ता'),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'आधार कार्ड क्रमांक (१२ अंक)',
                  hint: 'उदा. 1234 5678 9012',
                  controller: _aadhaarController,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  prefixIcon: Icons.credit_card,
                  validator: Validators.validateAadhaar,
                ),
                const SizedBox(height: 14),

                // Aadhaar Privacy Consent Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _aadhaarConsentGiven,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _aadhaarConsentGiven = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'मी सहमत आहे की आधार क्रमांक ओळख पडताळणीसाठी कूटबद्ध (encrypted) करून सुरक्षितपणे ठेवला जाईल. फक्त शेवटचे ४ अंकच दृश्यमान राहतील.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF78350F),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                CustomButton(
                  label: 'नोंदणी पूर्ण करा (Submit)',
                  icon: Icons.check,
                  isLoading: _isLoading,
                  backgroundColor: _role == UserRole.leader
                      ? AppColors.secondary
                      : AppColors.primary,
                  onPressed: _handleSubmit,
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
