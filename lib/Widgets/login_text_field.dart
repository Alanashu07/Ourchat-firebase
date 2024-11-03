import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final Widget? suffixIcon;
  final bool autofocus;
  final TextAlign textAlign;
  final Widget? prefixIcon;
  final Function(String value)? onSubmitted;
  final bool? filled;
  final bool hideText;
  final TextInputType? textInputType;
  final List<TextInputFormatter>? inputFormatters;
  final Color? fillColor;
  final TextCapitalization? textCapitalization;

  const LoginTextField(
      {super.key,
        required this.controller,
        this.textCapitalization,
        this.hintText,
        this.filled,
        this.fillColor,
        this.textInputType,
        this.hideText = false,
        this.inputFormatters,
        this.suffixIcon,
        this.prefixIcon,
        this.onSubmitted,
        this.autofocus = false,
        this.textAlign = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: TextFormField(
        controller: controller,
        keyboardType: textInputType,
        autofocus: autofocus,
        textAlign: textAlign,
        onFieldSubmitted: onSubmitted,
        validator: (value) => value!.isNotEmpty ? null : "This Field cannot be empty",
        inputFormatters: inputFormatters,
        maxLines: hideText ? 1 : 5,
        obscureText: hideText,
        minLines: 1,
        textCapitalization: textCapitalization ?? TextCapitalization.sentences,
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          fillColor: fillColor,
          filled: filled,
          hintText: hintText,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple)),
        ),
      ),
    );
  }
}
