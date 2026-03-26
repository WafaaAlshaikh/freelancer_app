import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {

  final String text;
  final VoidCallback onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false
  });

  @override
  Widget build(BuildContext context) {

    return ElevatedButton(

      onPressed: onPressed,

      child: loading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(text),

    );

  }

}