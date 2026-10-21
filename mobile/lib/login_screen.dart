import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  ConfirmationResult? _webConfirmation;
  String? _verificationId;
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() => _error = 'कृपया १० अंकी मोबाईल नंबर टाका');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final fullPhone = '+91$phone';
    try {
      if (kIsWeb) {
        _webConfirmation = await _auth.signInWithPhoneNumber(fullPhone);
        setState(() => _otpSent = true);
      } else {
        await _auth.verifyPhoneNumber(
          phoneNumber: fullPhone,
          verificationCompleted: (cred) async {
            await _auth.signInWithCredential(cred);
          },
          verificationFailed: (e) {
            setState(() => _error = 'त्रुटी: ${e.message}');
          },
          codeSent: (id, _) {
            setState(() {
              _verificationId = id;
              _otpSent = true;
            });
          },
          codeAutoRetrievalTimeout: (id) => _verificationId = id,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = 'त्रुटी: ${e.message}');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _error = '६ अंकी OTP टाका');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (kIsWeb) {
        await _webConfirmation!.confirm(code);
      } else {
        final cred = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: code,
        );
        await _auth.signInWithCredential(cred);
      }
    } on FirebaseAuthException {
      setState(() => _error = 'चुकीचा OTP, पुन्हा प्रयत्न करा');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  const Text('🌾', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 8),
                  const Text(
                    'ShetUdyami.AI',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const Text('शेतकरी ते उद्योजक, AI सोबत',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _phoneController,
                    enabled: !_otpSent,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: const TextStyle(fontSize: 22),
                    decoration: const InputDecoration(
                      labelText: 'मोबाईल नंबर',
                      prefixText: '+91 ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(fontSize: 22),
                      decoration: const InputDecoration(
                        labelText: 'OTP टाका',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed:
                          _loading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_otpSent ? 'लॉगिन करा' : 'OTP पाठवा',
                              style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}