import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool loading = false;

  void forgotPassword() async {
    setState(() => loading = true);
    final res = await ApiService.forgotPassword(emailController.text);
    setState(() => loading = false);

    Fluttertoast.showToast(msg: res['message']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Forgot Password')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
              SizedBox(height: 20),
              ElevatedButton(onPressed: forgotPassword, child: loading ? CircularProgressIndicator(color: Colors.white) : Text('Send Reset Email')),
            ],
          ),
        ),
      ),
    );
  }
}