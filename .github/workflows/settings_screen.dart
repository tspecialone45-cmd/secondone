import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    final locale = ref.watch(localeProvider);

    final langName = locale.languageCode == 'mr'
        ? 'मराठी'
        : locale.languageCode == 'hi'
            ? 'हिंदी'
            : 'English';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('सेटिंग्ज (Settings)'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    backgroundImage: user?.profilePhotoUrl != null
                        ? NetworkImage(user!.profilePhotoUrl!)
                        : null,
                    child: user?.profilePhotoUrl == null
                        ? Text(
                            user?.name.isNotEmpty == true ? user!.name[0] : 'म',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'वापरकर्ता', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('+91 ${user?.phone ?? ''}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text('आधार: XXXX-${user?.aadhaarLast4 ?? ''}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Preferences Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('प्राधान्ये व साधने (Preferences & Tools)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language, color: AppColors.primary),
                    title: const Text('ॲपची भाषा बदला (Change Language)'),
                    subtitle: Text('सध्या: $langName'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.push('/language'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined, color: AppColors.secondary),
                    title: const Text('सूचना केंद्र (Notifications)'),
                    subtitle: const Text('मासिक बचत व बैठक आठवण संदेश'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.push('/notifications'),
                  ),
                  if (user?.role.name == 'leader' || user?.role.name == 'deputy') ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.history_edu, color: Colors.brown),
                      title: const Text('ऑडिट नोंदवही (Audit Trail)'),
                      subtitle: const Text('आर्थिक व्यवहारांची कायमस्वरूपी नोंद'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.push('/audit-logs'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.group_outlined, color: Colors.indigo),
                      title: const Text('गट सदस्य व पदे (Roles)'),
                      subtitle: const Text('उपाध्यक्ष नियुक्ती व सदस्य यादी'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.push('/members-list'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Privacy & Info Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('सुरक्षा व माहिती (Privacy & Info)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.security, color: Colors.teal),
                    title: Text('आधार डेटा गोपनीयता'),
                    subtitle: Text('आपला आधार क्रमांक AES-256 कूटबद्ध असून फक्त शेवटचे ४ अंकच दिसतात.'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: Colors.blue),
                    title: Text('ॲप आवृत्ती (App Version)'),
                    subtitle: Text('महिला बचत गट v1.0.0 (Android)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Logout Button
            ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('लॉग आउट'),
                    content: const Text('तुम्हाला नक्की बाहेर पडायचे आहे का?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('नाही')),
                      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('होय')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('लॉग आउट करा (Logout)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
