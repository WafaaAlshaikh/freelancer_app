import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false
  });

  @override
  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical:10),

      child: TextField(

        controller: controller,
        obscureText: obscure,

        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
        ),

      ),

    );

  }

}