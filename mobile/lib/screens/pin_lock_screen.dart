import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/audit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pin_keypad.dart';
import 'login_screen.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const PinLockScreen({super.key, required this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredPin = '';

  Future<void> _onNumberTap(int number) async {
    final auth = context.read<AuthProvider>();
    if (auth.isPinBlocked) return;
    final pinLength = auth.expectedPinLength;
    if (_enteredPin.length >= pinLength) return;

    setState(() {
      _enteredPin += number.toString();
    });

    if (_enteredPin.length == pinLength) {
      final success = await auth.unlockWithPin(_enteredPin);
      if (success) {
        AuditService.logAction(action: 'PIN_UNLOCK', entityType: 'auth');
        widget.onUnlocked();
      } else if (mounted) {
        setState(() {
          _enteredPin = '';
        });
      }
    }
  }

  void _onBackspace() {
    if (context.read<AuthProvider>().isPinBlocked) return;
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pinLength = auth.expectedPinLength;
    final isBlocked = auth.isPinBlocked;
    final userName =
        auth.currentUser?.fullName ?? auth.currentUser?.username ?? 'Utilisateur';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Bonjour, $userName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entrez votre code PIN pour déverrouiller la caisse',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMedium),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pinLength, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isFilled ? AppColors.primary : AppColors.divider,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              if (auth.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    auth.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              PinKeypad(
                disabled: isBlocked,
                onDigitTap: _onNumberTap,
                onBackspace: _onBackspace,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: isBlocked
                    ? TextButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      )
                    : null,
                icon: const Icon(Icons.key_outlined, size: 16, color: AppColors.primary),
                label: const Text(
                  'Se connecter avec le mot de passe',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
