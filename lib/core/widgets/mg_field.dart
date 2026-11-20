import 'package:flutter/material.dart';
import '../theme/mg_colors.dart';
import '../theme/app_tokens.dart';

/// Campo de texto en casilla según la especificación de MiGasto:
/// Altura 56, radio 16, fondo `soft`, borde 1px `line` que pasa a 1.6px violeta al enfocar,
/// ícono a la izquierda que se tiñe de violeta en foco, y acción opcional a la derecha (ej. ojo de contraseña).
class MgField extends StatefulWidget {
  const MgField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<MgField> createState() => _MgFieldState();
}

class _MgFieldState extends State<MgField> {
  late final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: AppSizes.field,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: MgColors.soft,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(
          color: _isFocused ? MgColors.acc : MgColors.line,
          width: _isFocused ? 1.6 : 1.0,
        ),
      ),
      child: Row(
        children: [
          if (widget.prefixIcon != null) ...[
            Icon(
              widget.prefixIcon,
              size: 20,
              color: _isFocused ? MgColors.acc : MgColors.ink2,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              readOnly: widget.readOnly,
              onTap: widget.onTap,
              obscureText: widget.isPassword ? _obscureText : false,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: MgColors.ink,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.hintText,
                labelText: widget.labelText,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintStyle: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: MgColors.ink3,
                ),
                labelStyle: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: MgColors.ink2,
                ),
              ),
            ),
          ),
          if (widget.isPassword)
            IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: MgColors.ink2,
              ),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            )
          else if (widget.suffixIcon != null)
            widget.suffixIcon!,
        ],
      ),
    );
  }
}
