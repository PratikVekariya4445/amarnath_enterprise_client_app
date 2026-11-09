import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/core/theme/app_colors.dart';

/// Reusable input field component matching the Amarnath Enterprise design specification.
/// Features a rounded container, leading icon, stacked label & text field, and optional trailing widget.
class CustomAuthTextField extends StatelessWidget {
  const CustomAuthTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.leadingIcon,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.trailing,
    this.validator,
    this.inputFormatters,
    this.onChanged,
    this.textInputAction,
    this.onFieldSubmitted,
    this.errorText,
  });

  final String label;
  final String hintText;
  final IconData leadingIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final Widget? trailing;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(16.dp),
            border: Border.all(
              color: hasError ? AppColors.statusRejected : AppColors.inputBorder,
              width: 1.0,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16.dp,
            vertical: 10.dp,
          ),
          child: Row(
            crossAxisAlignment: maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              // Leading Icon in Brand Dark Green
              Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 4.dp : 0),
                child: Icon(
                  leadingIcon,
                  color: AppColors.primaryDarkGreen,
                  size: 24.dp,
                ),
              ),
              SizedBox(width: 14.dp),

              // Stacked Label & Input Field
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    SizedBox(height: 2.dp),
                    TextFormField(
                      controller: controller,
                      keyboardType: keyboardType,
                      obscureText: obscureText,
                      maxLines: maxLines,
                      validator: validator,
                      inputFormatters: inputFormatters,
                      onChanged: onChanged,
                      textInputAction: textInputAction,
                      onFieldSubmitted: onFieldSubmitted,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: AppColors.primaryDarkGreen,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: hintText,
                        hintStyle: TextStyle(
                          fontSize: 13.5.sp,
                          color: AppColors.textPlaceholder,
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),

              // Optional Trailing Widget (e.g. Password visibility toggle)
              if (trailing != null) ...[
                SizedBox(width: 8.dp),
                trailing!,
              ],
            ],
          ),
        ),

        // Inline Error Message if present
        if (hasError)
          Padding(
            padding: EdgeInsets.only(left: 12.dp, top: 4.dp),
            child: Text(
              errorText!,
              style: TextStyle(
                color: AppColors.statusRejected,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
