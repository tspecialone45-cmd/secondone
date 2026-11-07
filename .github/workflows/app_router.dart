import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/otp_screen.dart';
import 'presentation/screens/auth/registration_screen.dart';
import 'presentation/screens/group/create_group_screen.dart';
import 'presentation/screens/group/join_group_screen.dart';
import 'presentation/screens/language/language_selection_screen.dart';
import 'presentation/screens/leader/bank_book_screen.dart';
import 'presentation/screens/leader/group_settings_screen.dart';
import 'presentation/screens/leader/leader_dashboard.dart';
import 'presentation/screens/leader/loan_management_screen.dart';
import 'presentation/screens/leader/meeting_screen.dart';
import 'presentation/screens/leader/pending_requests_screen.dart';
import 'presentation/screens/leader/savings_collection_screen.dart';
import 'presentation/screens/member/loan_apply_screen.dart';
import 'presentation/screens/member/meeting_history_screen.dart';
import 'presentation/screens/member/member_dashboard.dart';
import 'presentation/screens/member/passbook_screen.dart';
import 'presentation/screens/leader/audit_log_screen.dart';
import 'presentation/screens/leader/member_management_screen.dart';
import 'presentation/screens/notifications/notifications_screen.dart';
import 'presentation/screens/reports/reports_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageSelectionScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return OtpScreen(phone: phone);
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        final phone = state.extra as String?;
        return RegistrationScreen(initialPhone: phone);
      },
    ),
    GoRoute(
      path: '/create-group',
      builder: (context, state) => const CreateGroupScreen(),
    ),
    GoRoute(
      path: '/join-group',
      builder: (context, state) => const JoinGroupScreen(),
    ),
    GoRoute(
      path: '/leader-dashboard',
      builder: (context, state) => const LeaderDashboard(),
    ),
    GoRoute(
      path: '/member-dashboard',
      builder: (context, state) => const MemberDashboard(),
    ),
    GoRoute(
      path: '/pending-requests',
      builder: (context, state) => const PendingRequestsScreen(),
    ),
    GoRoute(
      path: '/savings-collection',
      builder: (context, state) => const SavingsCollectionScreen(),
    ),
    GoRoute(
      path: '/loan-management',
      builder: (context, state) => const LoanManagementScreen(),
    ),
    GoRoute(
      path: '/meeting',
      builder: (context, state) => const MeetingScreen(),
    ),
    GoRoute(
      path: '/bank-book',
      builder: (context, state) => const BankBookScreen(),
    ),
    GoRoute(
      path: '/group-settings',
      builder: (context, state) => const GroupSettingsScreen(),
    ),
    GoRoute(
      path: '/passbook',
      builder: (context, state) => const PassbookScreen(),
    ),
    GoRoute(
      path: '/apply-loan',
      builder: (context, state) => const LoanApplyScreen(),
    ),
    GoRoute(
      path: '/meeting-history',
      builder: (context, state) => const MeetingHistoryScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/audit-logs',
      builder: (context, state) => const AuditLogScreen(),
    ),
    GoRoute(
      path: '/members-list',
      builder: (context, state) => const MemberManagementScreen(),
    ),
  ],
);
