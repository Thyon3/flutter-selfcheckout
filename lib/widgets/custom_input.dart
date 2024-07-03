import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/constants.dart';

class CustomInput extends StatelessWidget {
  final String hintText;
  final TextEditingController textEditingController;
  final TextInputType textInputType;
  final bool obscureText;
  final VoidCallback? onSubmitted;
  final VoidCallback? onChanged;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final bool enableSuggestions;
  final bool autocorrect;
  final TextCapitalization textCapitalization;

  CustomInput({
    required this.hintText,
    required this.textEditingController,
    this.textInputType = TextInputType.text,
    this.obscureText = false,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.sentences,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: textEditingController,
        keyboardType: textInputType,
        obscureText: obscureText,
        focusNode: focusNode,
        textInputAction: textInputAction,
        enableSuggestions: enableSuggestions,
        autocorrect: autocorrect,
        textCapitalization: textCapitalization,
        onSubmitted: (value) {
          if (onSubmitted != null) {
            onSubmitted!();
          }
        },
        onChanged: (value) {
          if (onChanged != null) {
            onChanged!();
          }
        },
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Constants.regularText.copyWith(
            color: Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 16.0,
          ),
        ),
        style: Constants.regularText,
      ),
    );
  }
}
