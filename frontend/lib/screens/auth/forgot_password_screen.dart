// forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelancer_platform/screens/auth/verify_reset_code_screen.dart';
import '../../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool loading = false;

  static const Color primaryPurple = Color(0xFF5B5BD6);

  void sendResetCode() async {
    if (emailController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your email");
      return;
    }

    setState(() => loading = true);
    final res = await ApiService.forgotPassword(emailController.text);
    setState(() => loading = false);

    Fluttertoast.showToast(msg: res['message']);

    if (res['hasCode'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              VerifyResetCodeScreen(email: emailController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF122543), Color(0xFF7C6FF7), Color(0xFF9B8FF7)],
          ),
        ),
        child: Center(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: primaryPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_reset, size: 40, color: primaryPurple),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter your email and we'll send you a reset code",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 28),

                TextField(
                  controller: emailController,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 14,
                  ),
                  cursorColor: primaryPurple,
                  decoration: InputDecoration(
                    hintText: "Email Address",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Colors.grey[400],
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(color: primaryPurple, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: loading ? null : sendResetCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Send Reset Code"),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Back to Login",
                    style: TextStyle(color: Colors.black54),
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
