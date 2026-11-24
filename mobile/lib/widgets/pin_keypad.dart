import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PinKeypad extends StatelessWidget {
  final bool disabled;
  final void Function(int digit) onDigitTap;
  final VoidCallback onBackspace;

  const PinKeypad({
    super.key,
    this.disabled = false,
    required this.onDigitTap,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.35 : 1.0,
      child: Column(
        children: [
          _row([1, 2, 3]),
          const SizedBox(height: 16),
          _row([4, 5, 6]),
          const SizedBox(height: 16),
          _row([7, 8, 9]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72, height: 72),
              _keypadButton('0', disabled ? null : () => onDigitTap(0)),
              SizedBox(
                width: 72,
                height: 72,
                child: IconButton(
                  onPressed: disabled ? null : onBackspace,
                  icon: const Icon(
                    Icons.backspace_outlined,
                    color: AppColors.textMedium,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<int> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map((d) => _keypadButton(d.toString(), disabled ? null : () => onDigitTap(d)))
          .toList(),
    );
  }

  Widget _keypadButton(String digit, VoidCallback? onTap) {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.primarySurface,
        shape: BoxShape.circle,
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
