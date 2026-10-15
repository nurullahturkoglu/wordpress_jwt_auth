import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.emptyMessage,
    this.obscureText = false,
    this.keyboardType,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String emptyMessage;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      autocorrect: false,
      validator: (value) =>
          value == null || value.trim().isEmpty ? widget.emptyMessage : null,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}
