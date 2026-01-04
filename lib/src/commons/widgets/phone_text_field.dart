import 'package:flutter/material.dart';

class CustomPhoneTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Color fillColor;
  final double borderRadius;
  final String? Function(String?)? validator;

  const CustomPhoneTextField({
    super.key,
    required this.controller,
    this.hintText = 'Enter Phone Number',
    this.fillColor = const Color(0xFFF5F5F5),
    this.borderRadius = 10.0,
    this.validator,
  });

  @override
  _CustomPhoneTextFieldState createState() => _CustomPhoneTextFieldState();
}

class _CustomPhoneTextFieldState extends State<CustomPhoneTextField> {
  String? errorMessage;

  void _validateInput(String value) {
    if (widget.validator != null) {
      setState(() {
        errorMessage = widget.validator!(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('+91'),
              Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),
        filled: true,
        fillColor: widget.fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide.none,
        ),
        hintText: widget.hintText,
        errorText: errorMessage,
      ),
      keyboardType: TextInputType.phone,
      onChanged: _validateInput,
    );
  }
}
