import 'package:flutter/material.dart';

class AuthFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const AuthFormField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}
