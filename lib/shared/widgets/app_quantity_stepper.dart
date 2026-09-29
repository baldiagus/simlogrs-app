import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

class AppQuantityStepper extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;
  final VoidCallback? onMaxReached;

  const AppQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max,
    this.onMaxReached,
  });

  @override
  State<AppQuantityStepper> createState() => _AppQuantityStepperState();
}

class _AppQuantityStepperState extends State<AppQuantityStepper> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final currentTextVal = int.tryParse(_controller.text);
      if (currentTextVal != widget.value) {
        _controller.text = '${widget.value}';
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      _commitValue();
    }
  }

  void _commitValue() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed < widget.min) {
      _controller.text = '${widget.min}';
      widget.onChanged(widget.min);
    } else if (widget.max != null && parsed > widget.max!) {
      _controller.text = '${widget.max}';
      widget.onChanged(widget.max!);
      widget.onMaxReached?.call();
    } else {
      _controller.text = '$parsed';
      widget.onChanged(parsed);
    }
  }

  void _handleTextChanged(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null) return;

    if (widget.max != null && parsed > widget.max!) {
      _controller.text = '${widget.max}';
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      widget.onChanged(widget.max!);
      widget.onMaxReached?.call();
    } else if (parsed >= widget.min) {
      widget.onChanged(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDecrease = widget.value > widget.min;
    final canIncrease = widget.max == null || widget.value < widget.max!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: canDecrease
                ? () {
                    final newVal = widget.value - 1;
                    _controller.text = '$newVal';
                    widget.onChanged(newVal);
                  }
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.minus,
                size: 14,
                color: canDecrease ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 42, maxWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: _handleTextChanged,
              onSubmitted: (_) => _commitValue(),
            ),
          ),
          InkWell(
            onTap: () {
              if (canIncrease) {
                final newVal = widget.value + 1;
                _controller.text = '$newVal';
                widget.onChanged(newVal);
              } else {
                widget.onMaxReached?.call();
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.plus,
                size: 14,
                color: canIncrease ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
