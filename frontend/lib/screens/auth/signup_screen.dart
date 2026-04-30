import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String role = 'client';
  bool loading = false;
  bool obscurePassword = true;

  static const Color primaryPurple = Color(0xFF5B5BD6);
  static const Color loginButtonColor = Color(0xFF122543);

  void signup() async {
    setState(() => loading = true);

    final res = await ApiService.signup(
      nameController.text,
      emailController.text,
      passwordController.text,
      role,
    );

    setState(() => loading = false);

    Fluttertoast.showToast(msg: res['message']);

    if (res['user'] != null) {
      Navigator.pushNamed(context, '/verify', arguments: emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF122543), Color(0xFF7C6FF7), Color(0xFF9B8FF7)],
          ),
        ),
        child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildLeftPanel()),

        _buildRightCard(width: 420),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: _buildLogo(),
            ),
            _buildRightCard(width: double.infinity),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          const SizedBox(height: 36),
          const Text(
            'Join iPal Today!',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Start your freelancing career',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Join thousands of freelancers and clients worldwide. Find work, hire talent, and get paid securely on iPal.',
            style: TextStyle(fontSize: 13, color: Colors.white60, height: 1.65),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        const Text(
          'iPal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildRightCard({required double width}) {
    return Container(
      width: width == double.infinity ? null : width,
      margin: const EdgeInsets.fromLTRB(20, 50, 50, 0),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            const SizedBox(height: 6),

            const Center(
              child: Text(
                'Join iPal and start earning today',
                style: TextStyle(fontSize: 13, color: Colors.black45),
              ),
            ),
            const SizedBox(height: 28),

            _buildTextField(
              controller: nameController,
              hint: 'Full Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 14),

            _buildTextField(
              controller: emailController,
              hint: 'Email Address',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 14),

            _buildTextField(
              controller: passwordController,
              hint: 'Password',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 14),

            _buildRoleDropdown(),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  disabledBackgroundColor: primaryPurple.withOpacity(0.7),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),

            _buildOrDivider(),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildSocialButton(
                    label: 'Google',
                    icon: _googleIcon(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSocialButton(
                    label: 'Facebook',
                    icon: _facebookIcon(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/login'),
                child: RichText(
                  text: const TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                    children: [
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(
                          color: primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: role,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFBBBBBB)),
          style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
          items: ['client', 'freelancer']
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      Icon(
                        e == 'client'
                            ? Icons.business_outlined
                            : Icons.person_outline,
                        color: primaryPurple,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        e == 'client'
                            ? 'Client (Hire Freelancers)'
                            : 'Freelancer (Find Work)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            setState(() {
              role = val!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscurePassword : false,
      style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFFBBBBBB), size: 20),
        suffixIcon: isPassword
            ? GestureDetector(
                onTap: () => setState(() => obscurePassword = !obscurePassword),
                child: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFFBBBBBB),
                  size: 20,
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: primaryPurple, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFEEEEEE), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFEEEEEE), thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButton({required String label, required Widget icon}) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: icon,
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 11),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }

  Widget _facebookIcon() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final redPaint = Paint()..color = const Color(0xFFEA4335);

    final bluePath = Path()
      ..moveTo(w, h * 0.5)
      ..arcTo(Rect.fromLTWH(0, 0, w, h), -0.25, 1.0, false)
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    final greenPath = Path()
      ..moveTo(w * 0.5, h)
      ..arcTo(Rect.fromLTWH(0, 0, w, h), 0.75, 1.0, false)
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    final yellowPath = Path()
      ..moveTo(0, h * 0.5)
      ..arcTo(Rect.fromLTWH(0, 0, w, h), 1.75, 1.0, false)
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    final redPath = Path()
      ..moveTo(w * 0.5, 0)
      ..arcTo(Rect.fromLTWH(0, 0, w, h), -1.25, 1.0, false)
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      w * 0.3,
      Paint()..color = Colors.white,
    );

    final gRect = Rect.fromLTWH(w * 0.5, h * 0.38, w * 0.42, h * 0.24);
    canvas.drawRect(gRect, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
