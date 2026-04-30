// reset_password_with_code_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

class ResetPasswordWithCodeScreen extends StatefulWidget {
  final String email;
  final String code;
  const ResetPasswordWithCodeScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordWithCodeScreen> createState() =>
      _ResetPasswordWithCodeScreenState();
}

class _ResetPasswordWithCodeScreenState
    extends State<ResetPasswordWithCodeScreen> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  static const Color primaryPurple = Color(0xFF5B5BD6);

  void resetPassword() async {
    if (passwordController.text != confirmPasswordController.text) {
      Fluttertoast.showToast(msg: "Passwords don't match");
      return;
    }

    if (passwordController.text.length < 6) {
      Fluttertoast.showToast(msg: "Password must be at least 6 characters");
      return;
    }

    setState(() => loading = true);

    final res = await ApiService.resetPasswordWithCode(
      email: widget.email,
      code: widget.code,
      newPassword: passwordController.text,
      confirmPassword: confirmPasswordController.text,
    );

    setState(() => loading = false);

    Fluttertoast.showToast(msg: res['message']);

    if (res['success'] == true) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
                  "Reset Password",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter your new password",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 28),

                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 14,
                  ),
                  cursorColor: primaryPurple,
                  decoration: InputDecoration(
                    hintText: "New Password",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Colors.grey[400],
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[400],
                      ),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
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
                const SizedBox(height: 14),

                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 14,
                  ),
                  cursorColor: primaryPurple,
                  decoration: InputDecoration(
                    hintText: "Confirm Password",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Colors.grey[400],
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[400],
                      ),
                      onPressed: () => setState(
                        () => obscureConfirmPassword = !obscureConfirmPassword,
                      ),
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
                    onPressed: loading ? null : resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Reset Password"),
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
