import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/brisko_logo.dart';
import 'auth_controller.dart';
import 'otp_models.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _mobile = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final raw = _mobile.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Enter your mobile number.');
      return;
    }
    if (!PhoneUtil.isValidIndianMobile(raw)) {
      setState(() => _error = 'Enter a valid 10-digit mobile number.');
      return;
    }
    final normalized = PhoneUtil.normalize(raw);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(otpAuthServiceProvider).sendOtp(normalized);
      if (!mounted) return;
      context.push('/otp?mobile=$normalized');
    } on OtpException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
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
                  'Sign in with your mobile number to order hot, fresh pizza.',
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
                Text(
                  'Mobile number',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  enabled: !_sending,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => _continue(),
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    counterText: '',
                    prefixText: '+91  ',
                    hintText: '98765 43210',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                          )
                        : const Text('Continue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'By continuing you agree to Brisko Pizza policies. We will send you a one-time password over SMS.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
