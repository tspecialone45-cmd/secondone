import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/app_exception.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  /// Sends 6-digit OTP to the Indian phone number (+91)
  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException e) onVerificationFailed,
    required void Function(PhoneAuthCredential credential) onVerificationCompleted,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) async {
    try {
      final formattedPhone = phone.startsWith('+91')
          ? phone
          : '+91${phone.replaceAll(RegExp(r'\D'), '')}';

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout ?? (_) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      throw AuthException('OTP पाठवण्यात त्रुटी आली: ${e.toString()}');
    }
  }

  /// Verifies OTP and returns UserCredential
  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'OTP अमान्य किंवा कालबाह्य झाला आहे.');
    } catch (e) {
      throw AuthException('सत्यापनात त्रुटी आली: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
