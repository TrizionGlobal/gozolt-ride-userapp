import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';

class OtpInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final bool hasError;
  final VoidCallback? onChanged;

  const OtpInputField({
    super.key,
    this.length = AppConstants.otpLength,
    required this.onCompleted,
    this.hasError = false,
    this.onChanged,
  });

  @override
  State<OtpInputField> createState() => OtpInputFieldState();
}

class OtpInputFieldState extends State<OtpInputField>
    with SingleTickerProviderStateMixin {
  late final List<String> _digits;
  late final FocusNode _focusNode;
  late final TextEditingController _hiddenController;
  AnimationController? _shakeController;
  Animation<double>? _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _digits = List.filled(widget.length, '');
    _focusNode = FocusNode();
    _hiddenController = TextEditingController();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeController!, curve: Curves.elasticIn),
    );

    // Auto-focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(OtpInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      shake();
    }
  }

  void shake() {
    _shakeController?.forward().then((_) => _shakeController?.reverse());
  }

  void clear() {
    _hiddenController.clear();
    setState(() {
      for (int i = 0; i < _digits.length; i++) {
        _digits[i] = '';
      }
    });
    _focusNode.requestFocus();
  }

  String get otp => _digits.join();

  int get _filledCount => _digits.where((d) => d.isNotEmpty).length;

  @override
  void dispose() {
    _focusNode.dispose();
    _hiddenController.dispose();
    _shakeController?.dispose();
    super.dispose();
  }

  void _onHiddenTextChanged(String value) {
    // Only allow digits, max length
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    final clamped = digitsOnly.length > widget.length
        ? digitsOnly.substring(0, widget.length)
        : digitsOnly;

    // Sync hidden controller if we clamped
    if (clamped != value) {
      _hiddenController.text = clamped;
      _hiddenController.selection = TextSelection.collapsed(
        offset: clamped.length,
      );
    }

    setState(() {
      for (int i = 0; i < widget.length; i++) {
        _digits[i] = i < clamped.length ? clamped[i] : '';
      }
    });

    widget.onChanged?.call();

    if (clamped.length == widget.length) {
      widget.onCompleted(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation!,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeAnimation!.value *
                (_shakeController!.status == AnimationStatus.forward ? 1 : -1),
            0,
          ),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
          SystemChannels.textInput.invokeMethod('TextInput.show');
        },
        child: Stack(
          children: [
            // Hidden text field that captures all keyboard input
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 1,
                child: TextField(
                  controller: _hiddenController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  maxLength: widget.length,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  onChanged: _onHiddenTextChanged,
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
            ),

            // Visual boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.length, (index) {
                final isFilled = _digits[index].isNotEmpty;
                final isActive = index == _filledCount && _focusNode.hasFocus;

                return GestureDetector(
                  onTap: () {
                    _focusNode.requestFocus();
                    SystemChannels.textInput.invokeMethod('TextInput.show');
                  },
                  child: Container(
                    width: 48,
                    height: 54,
                    margin: EdgeInsets.only(
                      right: index < widget.length - 1 ? 8 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.hasError
                            ? AppColors.error
                            : isFilled
                                ? AppColors.primaryGold
                                : isActive
                                    ? AppColors.primaryGold
                                    : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                        width: isActive || isFilled ? 2 : 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isFilled
                        ? Text(
                            _digits[index],
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : isActive
                            ? Container(
                                width: 2,
                                height: 24,
                                color: AppColors.primaryGold,
                              )
                            : null,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
