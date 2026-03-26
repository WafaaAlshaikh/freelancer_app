import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  void login() async {
    setState(() {
      loading = true;
    });
    

    final res = await ApiService.login(
      emailController.text,
      passwordController.text,
    );

    setState(() {
      loading = false;
    });

    if (res['token'] != null) {
      Fluttertoast.showToast(msg: res['message']);

      final userRole = res['user']?['role'];

      if (userRole == 'freelancer') {
        Navigator.pushReplacementNamed(context, '/freelancer/home');
      } else if (userRole == 'client') {
        Navigator.pushReplacementNamed(context, '/client/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Fluttertoast.showToast(msg: res['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffEFE7DF),

      body: Center(
        child: Container(
          width: screenWidth > 900 ? 900 : screenWidth * .95,
          height: 520,

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),

            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),

          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "Welcome Back!!",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 35),

                      TextField(
                        controller: emailController,

                        decoration: InputDecoration(
                          hintText: "Email",

                          prefixIcon: const Icon(Icons.email_outlined),

                          filled: true,
                          fillColor: const Color(0xffF5F5F5),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: passwordController,
                        obscureText: true,

                        decoration: InputDecoration(
                          hintText: "Password",

                          prefixIcon: const Icon(Icons.lock_outline),

                          suffixIcon: const Icon(Icons.visibility_off),

                          filled: true,
                          fillColor: const Color(0xffF5F5F5),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,

                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/forgot');
                          },

                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 50,

                        child: ElevatedButton(
                          onPressed: login,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffE6C4A4),

                            elevation: 0,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),

                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          IconButton(
                            icon: const Icon(Icons.g_mobiledata, size: 30),
                            onPressed: () {},
                          ),

                          const SizedBox(width: 20),

                          IconButton(
                            icon: const Icon(
                              Icons.facebook,
                              color: Colors.blue,
                            ),
                            onPressed: () {},
                          ),

                          const SizedBox(width: 20),

                          IconButton(
                            icon: const Icon(Icons.apple),
                            onPressed: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },

                          child: const Text(
                            "Don't have an account? Sign up",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (screenWidth > 700)
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xffEFE7DF),

                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),

                    child: Center(
                      child: Image.asset("assets/images/login.jpg", width: 320),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
