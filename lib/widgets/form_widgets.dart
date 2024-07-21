import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:selfcheckoutapp/constants.dart';
import 'package:selfcheckoutapp/utils/app_utils.dart';

class FormFieldWrapper extends StatelessWidget {
  final String? label;
  final Widget child;
  final String? errorText;
  final String? helperText;
  final bool required;
  final Widget? suffix;
  final Widget? prefix;

  const FormFieldWrapper({
    this.label,
    required this.child,
    this.errorText,
    this.helperText,
    this.required = false,
    this.suffix,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: Constants.regularText.copyWith(
                  fontWeight: FontWeight.w500,
                  color: errorText != null ? Colors.red : Colors.black87,
                ),
              ),
              if (required) ...[
                SizedBox(width: 4),
                Text(
                  '*',
                  style: Constants.regularText.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8),
        ],
        InputDecorator(
          decoration: InputDecoration(
            errorText: errorText,
            helperText: helperText,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            suffix: suffix,
            prefix: prefix,
          ),
          child: child,
        ),
      ],
    );
  }
}

class ValidatedTextField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final String? initialValue;
  final bool required;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  const ValidatedTextField({
    this.label,
    this.hintText,
    this.initialValue,
    this.required = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.controller,
    this.focusNode,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  _ValidatedTextFieldState createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String? _errorText;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    
    _controller.addListener(_validateInput);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _validateInput() {
    if (widget.validator != null) {
      final error = widget.validator!(_controller.text);
      if (_errorText != error) {
        setState(() {
          _errorText = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: widget.label,
      errorText: _errorText,
      required: widget.required,
      suffix: widget.suffixIcon,
      prefix: widget.prefixIcon,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        onChanged: (value) {
          _validateInput();
          widget.onChanged?.call(value);
        },
        onTap: widget.onTap,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        enabled: widget.enabled,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        autofocus: widget.autofocus,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.inputBorderRadius),
            borderSide: BorderSide(
              color: _errorText != null 
                  ? Colors.red 
                  : _isFocused 
                      ? Constants.primaryColor 
                      : Colors.grey[300]!,
              width: _isFocused ? 2.0 : 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.inputBorderRadius),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.inputBorderRadius),
            borderSide: BorderSide(color: Constants.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.inputBorderRadius),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.inputBorderRadius),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: widget.enabled ? Colors.white : Colors.grey[100],
        ),
      ),
    );
  }
}

class EmailField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? initialValue;
  final bool required;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const EmailField({
    this.label,
    this.hintText,
    this.initialValue,
    this.required = true,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      label: label ?? 'Email',
      hintText: hintText ?? 'Enter your email',
      initialValue: initialValue,
      required: required,
      keyboardType: TextInputType.emailAddress,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Email is required';
        }
        if (value != null && value.trim().isNotEmpty && !AppUtils.isValidEmail(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
      ],
    );
  }
}

class PasswordField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final String? initialValue;
  final bool required;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int? minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSpecialChars;

  const PasswordField({
    this.label,
    this.hintText,
    this.initialValue,
    this.required = true,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
    this.minLength,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireNumbers = true,
    this.requireSpecialChars = false,
  });

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      label: widget.label ?? 'Password',
      hintText: widget.hintText ?? 'Enter your password',
      initialValue: widget.initialValue,
      required: widget.required,
      obscureText: _obscureText,
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      validator: (value) {
        if (widget.required && (value == null || value.isEmpty)) {
          return 'Password is required';
        }
        if (value != null && value.isNotEmpty) {
          if (widget.minLength != null && value.length < widget.minLength!) {
            return 'Password must be at least ${widget.minLength} characters';
          }
          if (widget.requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
            return 'Password must contain at least one uppercase letter';
          }
          if (widget.requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
            return 'Password must contain at least one lowercase letter';
          }
          if (widget.requireNumbers && !value.contains(RegExp(r'[0-9]'))) {
            return 'Password must contain at least one number';
          }
          if (widget.requireSpecialChars && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
            return 'Password must contain at least one special character';
          }
        }
        return null;
      },
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey[600],
        ),
        onPressed: _toggleVisibility,
      ),
    );
  }
}

class PhoneField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? initialValue;
  final bool required;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const PhoneField({
    this.label,
    this.hintText,
    this.initialValue,
    this.required = false,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      label: label ?? 'Phone Number',
      hintText: hintText ?? 'Enter your phone number',
      initialValue: initialValue,
      required: required,
      keyboardType: TextInputType.phone,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Phone number is required';
        }
        if (value != null && value.trim().isNotEmpty && !AppUtils.isValidPhone(value)) {
          return 'Please enter a valid phone number';
        }
        return null;
      },
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }
}

class NameField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? initialValue;
  final bool required;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int? minLength;
  final int? maxLength;

  const NameField({
    this.label,
    this.hintText,
    this.initialValue,
    this.required = true,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
    this.minLength,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      label: label ?? 'Name',
      hintText: hintText ?? 'Enter your name',
      initialValue: initialValue,
      required: required,
      keyboardType: TextInputType.name,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      maxLength: maxLength,
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Name is required';
        }
        if (value != null && value.trim().isNotEmpty) {
          if (minLength != null && value.trim().length < minLength!) {
            return 'Name must be at least $minLength characters';
          }
          if (value.trim().length < 2) {
            return 'Name must be at least 2 characters';
          }
          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
            return 'Name can only contain letters and spaces';
          }
        }
        return null;
      },
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
      ],
    );
  }
}

class TextArea extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? initialValue;
  final bool required;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final String? Function(String?)? validator;

  const TextArea({
    this.label,
    this.hintText,
    this.initialValue,
    this.required = false,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.maxLines = 5,
    this.minLines = 3,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      label: label,
      hintText: hintText,
      initialValue: initialValue,
      required: required,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator ?? (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }
}

class NumberField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final num? initialValue;
  final bool required;
  final ValueChanged<num>? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final num? min;
  final num? max;
  final bool isInteger;

  const NumberField({
    this.label,
    this.hintText,
    this.initialValue,
    this.required = false,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
    this.min,
    this.max,
    this.isInteger = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      label: label,
      hintText: hintText,
      initialValue: initialValue?.toString(),
      required: required,
      keyboardType: isInteger ? TextInputType.number : TextInputType.numberWithOptions(decimal: true),
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      textInputAction: textInputAction,
      onSubmitted: (value) {
        final numValue = isInteger ? int.tryParse(value) : double.tryParse(value);
        if (numValue != null) {
          onSubmitted?.call(value);
        }
      },
      onChanged: (value) {
        final numValue = isInteger ? int.tryParse(value) : double.tryParse(value);
        if (numValue != null) {
          onChanged?.call(numValue);
        }
      },
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'This field is required';
        }
        if (value != null && value.trim().isNotEmpty) {
          final numValue = isInteger ? int.tryParse(value) : double.tryParse(value);
          if (numValue == null) {
            return 'Please enter a valid number';
          }
          if (min != null && numValue < min!) {
            return 'Value must be at least $min';
          }
          if (max != null && numValue > max!) {
            return 'Value must be at most $max';
          }
        }
        return null;
      },
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
    );
  }
}

class DropdownFormField<T> extends StatelessWidget {
  final String? label;
  final String? hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool required;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const DropdownFormField({
    this.label,
    this.hintText,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.required = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    String? errorText;
    if (validator != null) {
      errorText = validator!(value);
    }

    return FormFieldWrapper(
      label: label,
      errorText: errorText,
      required: required,
      prefix: prefixIcon,
      suffix: suffixIcon,
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: enabled ? onChanged : null,
        validator: (value) {
          if (required && value == null) {
            return 'This field is required';
          }
          return validator?.call(value);
        },
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.inputBorderRadius),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
      ),
    );
  }
}

class CheckboxFormField extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? Function(bool?)? validator;
  final bool required;
  final bool enabled;
  final Color? activeColor;
  final MaterialTapTargetSize? materialTapTargetSize;

  const CheckboxFormField({
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.validator,
    this.required = false,
    this.enabled = true,
    this.activeColor,
    this.materialTapTargetSize,
  });

  @override
  Widget build(BuildContext context) {
    String? errorText;
    if (validator != null) {
      errorText = validator!(value);
    }

    return FormFieldWrapper(
      label: null,
      errorText: errorText,
      required: required,
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: activeColor,
            materialTapTargetSize: materialTapTargetSize,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Constants.regularText.copyWith(
                    color: enabled ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Constants.smallText.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SwitchFormField extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? Function(bool?)? validator;
  final bool required;
  final bool enabled;
  final Color? activeColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;

  const SwitchFormField({
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.validator,
    this.required = false,
    this.enabled = true,
    this.activeColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
  });

  @override
  Widget build(BuildContext context) {
    String? errorText;
    if (validator != null) {
      errorText = validator!(value);
    }

    return FormFieldWrapper(
      label: null,
      errorText: errorText,
      required: required,
      child: Row(
        children: [
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: activeColor,
            inactiveThumbColor: inactiveThumbColor,
            inactiveTrackColor: inactiveTrackColor,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Constants.regularText.copyWith(
                    color: enabled ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Constants.smallText.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
