import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GozoltButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final double? width;

  const GozoltButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
  });

  @override
  State<GozoltButton> createState() => _GozoltButtonState();
}

class _GozoltButtonState extends State<GozoltButton> {
  bool _debouncing = false;

  void _handlePress() {
    if (_debouncing || widget.onPressed == null) return;
    _debouncing = true;
    widget.onPressed!();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _debouncing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Theme.of(context).scaffoldBackgroundColor),
            ),
          )
        : Text(widget.label);

    final effectiveOnPressed = widget.isLoading || _debouncing ? null : _handlePress;

    if (widget.isOutlined) {
      return SizedBox(
        width: widget.width,
        child: OutlinedButton(onPressed: effectiveOnPressed, child: child),
      );
    }

    return SizedBox(
      width: widget.width,
      child: ElevatedButton(
        onPressed: effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
        ),
        child: child,
      ),
    );
  }
}
