import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppToast {
  static OverlayEntry? _currentEntry;

  static void _show({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final topPadding = MediaQuery.of(ctx).padding.top + 12;

        return Positioned(
          top: topPadding,
          right: 16,
          left: screenWidth > 500 ? screenWidth - 400 : 16,
          child: Material(
            color: Colors.transparent,
            elevation: 0,
            child: _ToastWidget(
              message: message,
              icon: icon,
              iconColor: iconColor,
              borderColor: borderColor,
              onDismiss: () {
                entry.remove();
                if (_currentEntry == entry) _currentEntry = null;
              },
            ),
          ),
        );
      },
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    Future.delayed(const Duration(milliseconds: 3800), () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }

  static void showError(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.danger,
      borderColor: AppColors.danger.withAlpha(140),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
      borderColor: AppColors.success.withAlpha(140),
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.warning,
      borderColor: AppColors.warning.withAlpha(140),
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.borderColor, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.iconColor.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onDismiss,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textMedium,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
