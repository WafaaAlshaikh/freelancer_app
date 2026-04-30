// verify_reset_code_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelancer_platform/screens/auth/reset_password_screen.dart';
import '../../services/api_service.dart';

class VerifyResetCodeScreen extends StatefulWidget {
  final String email;
  const VerifyResetCodeScreen({super.key, required this.email});

  @override
  State<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen> {
  final codeController = TextEditingController();
  bool loading = false;

  static const Color primaryPurple = Color(0xFF5B5BD6);

  void verifyCode() async {
    if (codeController.text.length != 6) {
      Fluttertoast.showToast(msg: "Please enter 6-digit code");
      return;
    }

    setState(() => loading = true);
    final res = await ApiService.verifyResetCode(
      widget.email,
      codeController.text,
    );
    setState(() => loading = false);

    if (res['valid'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordWithCodeScreen(
            email: widget.email,
            code: codeController.text,
          ),
        ),
      );
    } else {
      Fluttertoast.showToast(msg: res['message']);
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
                  child: Icon(Icons.security, size: 40, color: primaryPurple),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Verify Code",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter the 6-digit code sent to\n${widget.email}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 28),

                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  cursorColor: primaryPurple,
                  decoration: InputDecoration(
                    hintText: "• • • • • •",
                    hintStyle: TextStyle(color: Colors.grey[300], fontSize: 24),
                    counterText: "",
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primaryPurple, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: loading ? null : verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Verify Code"),
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
