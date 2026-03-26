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

  void signup() async {

    setState(() {
      loading = true;
    });

    final res = await ApiService.signup(
        nameController.text,
        emailController.text,
        passwordController.text,
        role
    );

    setState(() {
      loading = false;
    });

    Fluttertoast.showToast(msg: res['message']);

    if(res['user'] != null){
      Navigator.pushNamed(
          context,
          '/verify',
          arguments: emailController.text
      );
    }

  }

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;

    return Scaffold(

      backgroundColor: const Color(0xffEFE7DF),

      body: Center(

        child: Container(

          width: width > 900 ? 900 : width * .95,
          height: 560,

          decoration: BoxDecoration(

            color: Colors.white,
            borderRadius: BorderRadius.circular(25),

            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0,10),
              )
            ],

          ),

          child: Row(

            children: [


              Expanded(

                child: Padding(

                  padding: const EdgeInsets.symmetric(horizontal:40),

                  child: SingleChildScrollView(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        const SizedBox(height:40),

                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height:30),


                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: "Name",
                            prefixIcon: const Icon(Icons.person_outline),
                            filled: true,
                            fillColor: const Color(0xffF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height:20),


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

                        const SizedBox(height:20),


                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            filled: true,
                            fillColor: const Color(0xffF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height:20),


                        Container(

                          padding: const EdgeInsets.symmetric(horizontal:20),

                          decoration: BoxDecoration(
                            color: const Color(0xffF5F5F5),
                            borderRadius: BorderRadius.circular(30),
                          ),

                          child: DropdownButtonHideUnderline(

                            child: DropdownButton<String>(

                              value: role,

                              items: ['client','freelancer']
                                  .map((e)=>DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              )).toList(),

                              onChanged: (val){
                                setState(() {
                                  role = val!;
                                });
                              },

                            ),

                          ),

                        ),

                        const SizedBox(height:30),


                        SizedBox(

                          width: double.infinity,
                          height: 50,

                          child: ElevatedButton(

                            onPressed: signup,

                            style: ElevatedButton.styleFrom(

                              backgroundColor: const Color(0xffE6C4A4),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),

                            ),

                            child: loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Signup"),

                          ),

                        ),

                        const SizedBox(height:20),

                        Center(

                          child: TextButton(

                            onPressed: (){
                              Navigator.pushNamed(context, '/login');
                            },

                            child: const Text(
                              "Already have an account? Login",
                              style: TextStyle(color: Colors.black54),
                            ),

                          ),

                        )

                      ],

                    ),

                  ),

                ),

              ),


              if(width > 700)

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

                      child: Image.asset(
                        "assets/images/login.jpg",
                        width: 320,
                      ),

                    ),

                  ),

                )

            ],

          ),

        ),

      ),

    );

  }

}