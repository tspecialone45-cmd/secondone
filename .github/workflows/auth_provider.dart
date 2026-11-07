import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/member_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value(null);
  return ref.watch(memberRepositoryProvider).watchUserProfile(authUser.uid);
});

class AuthState {
  final bool isLoading;
  final String? verificationId;
  final String? error;
  final bool isOtpSent;
  final bool isAuthenticated;
  final UserRole selectedRole;

  AuthState({
    this.isLoading = false,
    this.verificationId,
    this.error,
    this.isOtpSent = false,
    this.isAuthenticated = false,
    this.selectedRole = UserRole.member,
  });

  AuthState copyWith({
    bool? isLoading,
    String? verificationId,
    String? error,
    bool? isOtpSent,
    bool? isAuthenticated,
    UserRole? selectedRole,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      verificationId: verificationId ?? this.verificationId,
      error: error,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      selectedRole: selectedRole ?? this.selectedRole,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final MemberRepository _memberRepository;

  AuthNotifier(this._authRepository, this._memberRepository) : super(AuthState());

  void setRole(UserRole role) {
    state = state.copyWith(selectedRole: role);
  }

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.sendOtp(
        phone: phone,
        onCodeSent: (verificationId, resendToken) {
          state = state.copyWith(
            isLoading: false,
            verificationId: verificationId,
            isOtpSent: true,
          );
        },
        onVerificationFailed: (e) {
          state = state.copyWith(
            isLoading: false,
            error: e.message ?? 'OTP पाठवण्यात त्रुटी आली.',
          );
        },
        onVerificationCompleted: (credential) async {
          // Auto retrieval
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            state = state.copyWith(isLoading: false, isAuthenticated: true);
          } catch (e) {
            state = state.copyWith(isLoading: false, error: e.toString());
          }
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> verifyOtp(String smsCode) async {
    if (state.verificationId == null) {
      state = state.copyWith(error: 'कृपया आधी OTP मागवा.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.verifyOtp(
        verificationId: state.verificationId!,
        smsCode: smsCode,
      );
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> registerProfile(UserModel user) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _memberRepository.createUserProfile(user);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = AuthState();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final memberRepo = ref.watch(memberRepositoryProvider);
  return AuthNotifier(authRepo, memberRepo);
});
