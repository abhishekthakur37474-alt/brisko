import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/brisko_logo.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _google() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider).signInWithGoogle();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              const BriskoLogo(size: 76),
              const SizedBox(height: 24),
              Text(AppStrings.appName, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                AppStrings.tagline,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sign in to order hot, fresh pizza.',
                style: TextStyle(color: AppColors.muted),
              ),
              const Spacer(),
              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                  child: Text(_error!, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _google,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.black,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _GoogleMark(),
                            SizedBox(width: 12),
                            Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'By continuing you agree to Brisko Pizza policies. We never see your Google password.',
                style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}
