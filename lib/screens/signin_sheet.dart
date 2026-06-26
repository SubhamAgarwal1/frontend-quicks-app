import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../state/providers.dart';

/// Bottom sheet that slides up over a dimmed splash. Google / Apple / Email / skip.
/// Returns true when a session was established.
Future<bool> showSignInSheet(BuildContext context, WidgetRef ref) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => const _SignInSheet(),
  );
  return result ?? false;
}

class _SignInSheet extends ConsumerStatefulWidget {
  const _SignInSheet();

  @override
  ConsumerState<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends ConsumerState<_SignInSheet> {
  bool _emailMode = false;
  bool _busy = false;
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (!mounted) return;
    final state = ref.read(authProvider);
    setState(() => _busy = false);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign-in failed. Try again.')),
      );
      return;
    }
    if (state.value != null && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authProvider.notifier);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.surfaceRaised,
          border: Border(top: BorderSide(color: AppColors.border)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF2E2F33),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 22),
            Text('Save your progress', style: AppText.heading(size: 22)),
            const SizedBox(height: 6),
            Text('Sign in to keep your Brain across devices.',
                textAlign: TextAlign.center,
                style: AppText.body(size: 13, color: AppColors.textDim)),
            const SizedBox(height: 24),
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
              )
            else if (_emailMode)
              _emailForm(auth)
            else
              _providerButtons(auth),
          ],
        ),
      ),
    );
  }

  Widget _providerButtons(AuthController auth) {
    return Column(
      children: [
        _ProviderButton(
          icon: Icons.g_mobiledata,
          label: 'Continue with Google',
          onTap: () => _run(auth.google),
        ),
        const SizedBox(height: 12),
        _ProviderButton(
          icon: Icons.apple,
          label: 'Continue with Apple',
          onTap: () => _run(auth.apple),
        ),
        const SizedBox(height: 12),
        _ProviderButton(
          icon: Icons.alternate_email,
          label: 'Continue with Email',
          onTap: () => setState(() => _emailMode = true),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: () => _run(auth.guest),
          child: Text('CONTINUE WITHOUT SIGNING IN',
              style: AppText.label(size: 10, color: AppColors.textMuted, tracking: 0.14)),
        ),
      ],
    );
  }

  Widget _emailForm(AuthController auth) {
    return Column(
      children: [
        _Field(controller: _email, hint: 'Email', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _Field(controller: _password, hint: 'Password', obscure: true),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: AppColors.ground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (_email.text.trim().isEmpty || _password.text.isEmpty) return;
              _run(() => auth.email(_email.text.trim(), _password.text));
            },
            child: Text('Sign in', style: AppText.body(size: 14, color: AppColors.ground, weight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() => _emailMode = false),
          child: Text('Back', style: AppText.body(size: 13, color: AppColors.textDim)),
        ),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF3A3B3F)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 20, color: AppColors.textCard),
        label: Text(label, style: AppText.body(size: 14, color: AppColors.textCard)),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint, this.obscure = false, this.keyboardType});
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: AppText.body(size: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(size: 14, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal),
        ),
      ),
    );
  }
}
