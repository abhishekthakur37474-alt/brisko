import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/brisko_top_bar.dart';
import 'auth_controller.dart';
import 'otp_models.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.mobile});

  final String mobile;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _length = 6;
  static const int _resendSeconds = 30;

  final _otp = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _resendIn = _resendSeconds;
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendIn = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendIn <= 1) {
        t.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn -= 1);
      }
    });
  }

  void _onChanged(String value) {
    setState(() => _error = null);
    if (value.length == _length && !_verifying) {
      _verify();
    }
  }

  Future<void> _verify() async {
    final code = _otp.text.trim();
    if (code.length != _length) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final result = await ref.read(otpAuthServiceProvider).verifyOtp(mobile: widget.mobile, otp: code);
      await ref.read(authControllerProvider).signInWithCustomToken(result.customToken, phone: widget.mobile);
      if (!mounted) return;
      context.go('/location');
    } on OtpException catch (e) {
      setState(() => _error = e.message);
      _otp.clear();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      _otp.clear();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resendIn > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref.read(otpAuthServiceProvider).resendOtp(widget.mobile);
      if (!mounted) return;
      _otp.clear();
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully')),
      );
    } on OtpException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _resendIn == 0 && !_resending;
    return Scaffold(
      backgroundColor: AppColors.warmBg,
      body: Column(
        children: [
          BriskoTopBar(
            title: 'Verify number',
            subtitle: 'Enter the code we sent you',
            circularBack: true,
            onBack: () => context.go('/login'),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Enter verification code',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 22, color: AppColors.text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit OTP to ${PhoneUtil.display(widget.mobile)}',
                    style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () => _focus.requestFocus(),
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          children: [
                            for (int i = 0; i < _length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(child: _box(i)),
                            ],
                          ],
                        ),
                        SizedBox(
                          width: 1,
                          height: 1,
                          child: Opacity(
                            opacity: 0,
                            child: TextField(
                              controller: _otp,
                              focusNode: _focus,
                              autofocus: true,
                              enabled: !_verifying,
                              keyboardType: TextInputType.number,
                              maxLength: _length,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: _onChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                      onPressed: _verifying ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _verifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                            )
                          : const Text('Verify', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Didn't receive the code?",
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: canResend ? _resend : null,
                          child: Text(
                            canResend ? 'Resend OTP' : 'Resend OTP in ${_resendIn}s',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: canResend ? AppColors.primary : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(int index) {
    final text = _otp.text;
    final filled = index < text.length;
    final active = index == text.length && !_verifying;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppColors.primary : (filled ? AppColors.primary.withValues(alpha: 0.45) : AppColors.border),
          width: active || filled ? 1.6 : 1,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Text(
        filled ? text[index] : '',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.text),
      ),
    );
  }
}