import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {

  final codeController = TextEditingController();
  bool loading = false;

  void verify(String email) async {

    setState(() {
      loading = true;
    });

    final res = await ApiService.verifyEmail(
        email,
        codeController.text
    );

    setState(() {
      loading = false;
    });

    Fluttertoast.showToast(msg: res['message']);

    if(res['message'].contains('success')){
      Navigator.pushReplacementNamed(context, '/login');
    }

  }

  @override
  Widget build(BuildContext context) {

    final email = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(

      backgroundColor: const Color(0xffEFE7DF),

      body: Center(

        child: Container(

          width: 450,
          padding: const EdgeInsets.all(40),

          decoration: BoxDecoration(

            color: Colors.white,
            borderRadius: BorderRadius.circular(25),

            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
              )
            ],

          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              const Text(
                "Verify Email",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height:20),

              Text(
                "Enter the code sent to\n$email",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),

              const SizedBox(height:30),

              TextField(

                controller: codeController,

                decoration: InputDecoration(

                  hintText: "Verification Code",

                  prefixIcon: const Icon(Icons.verified),

                  filled: true,
                  fillColor: const Color(0xffF5F5F5),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),

                ),

              ),

              const SizedBox(height:30),

              SizedBox(

                width: double.infinity,
                height: 50,

                child: ElevatedButton(

                  onPressed: ()=>verify(email),

                  style: ElevatedButton.styleFrom(

                    backgroundColor: const Color(0xffE6C4A4),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),

                  ),

                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Verify"),

                ),

              )

            ],

          ),

        ),

      ),

    );

  }

}