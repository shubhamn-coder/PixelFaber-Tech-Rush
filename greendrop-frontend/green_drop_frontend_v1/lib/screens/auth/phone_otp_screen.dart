import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';

class PhoneOtpScreen extends StatefulWidget {
  final String phoneNumber;
  const PhoneOtpScreen({super.key, required this.phoneNumber});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen>
    with SingleTickerProviderStateMixin {
  // ── OTP fields (6 separate controllers) ──
  final List<TextEditingController> _ctrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focus = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isSending = false;
  int _countdown = 60;
  Timer? _timer;
  String? _testOtp; // shown in demo mode
  String? _errorMsg;

  // ── animation ──
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
  late final Animation<double> _shakeAnim = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
  ]).animate(_shake);

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shake.dispose();
    for (final c in _ctrl) { c.dispose(); }
    for (final f in _focus) { f.dispose(); }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) {
        t.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendOtp() async {
    setState(() { _isSending = true; _errorMsg = null; _testOtp = null; });
    try {
      final res = await ApiService.post('/auth/send-otp', {
        'phoneNumber': widget.phoneNumber,
      });
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        _startCountdown();
        setState(() => _testOtp = data['testOtp']?.toString());
      } else {
        setState(() => _errorMsg = data['error'] ?? 'Failed to send OTP.');
      }
    } catch (_) {
      setState(() => _errorMsg = 'Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String get _otpValue => _ctrl.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final otp = _otpValue;
    if (otp.length < 6) {
      setState(() => _errorMsg = 'Please enter all 6 digits.');
      _shake.forward(from: 0);
      return;
    }
    setState(() { _isVerifying = true; _errorMsg = null; });
    try {
      final res = await ApiService.post('/auth/verify-otp', {
        'phoneNumber': widget.phoneNumber,
        'otp': otp,
      });
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context, data['verifyToken'] as String);
      } else {
        setState(() => _errorMsg = data['error'] ?? 'Incorrect OTP. Try again.');
        _shake.forward(from: 0);
        // clear boxes on wrong OTP
        for (final c in _ctrl) { c.clear(); }
        _focus[0].requestFocus();
      }
    } catch (_) {
      setState(() => _errorMsg = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focus[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focus[index - 1].requestFocus();
    }
    // Auto-submit when all 6 filled
    if (_otpValue.length == 6) {
      _verifyOtp();
    }
  }

  // ══════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final masked = _maskPhone(widget.phoneNumber);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E5631),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Phone Verification',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // ── icon ──
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E5631).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 38,
                  color: Color(0xFF1E5631),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Verify Your Phone',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit OTP to\n$masked',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),

              // ── TEST OTP DEMO BANNER ──
              if (_testOtp != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCC02), width: 1.3),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Color(0xFFF57F17), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TEST MODE — Your OTP:',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF795548),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _testOtp!,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B5E20),
                                letterSpacing: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF555555)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _testOtp!));
                          // auto-fill the boxes
                          for (var i = 0; i < 6 && i < _testOtp!.length; i++) {
                            _ctrl[i].text = _testOtp![i];
                          }
                          setState(() {});
                        },
                        tooltip: 'Copy & fill',
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ── 6-digit OTP boxes ──
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (context, child) => Transform.translate(
                  offset: Offset(_shakeAnim.value, 0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (i) => _otpBox(i)),
                ),
              ),

              // ── error message ──
              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMsg!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],

              const SizedBox(height: 28),

              // ── Verify button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isVerifying ? null : _verifyOtp,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Verify & Continue',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.verified_user_rounded, size: 18),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 18),

              // ── Resend row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive it? ",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  _countdown > 0
                      ? Text(
                          'Resend in ${_countdown}s',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF888888)),
                        )
                      : GestureDetector(
                          onTap: _isSending ? null : _sendOtp,
                          child: Text(
                            _isSending ? 'Sending…' : 'Resend OTP',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                ],
              ),

              const SizedBox(height: 24),

              // ── security note ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Color(0xFF388E3C)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your phone number is used only for account security verification and will never be shared.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 44,
      height: 54,
      child: TextField(
        controller: _ctrl[index],
        focusNode: _focus[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1B5E20),
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: _ctrl[index].text.isNotEmpty
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFCCCCCC),
              width: _ctrl[index].text.isNotEmpty ? 2 : 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFF2E7D32), width: 2.2),
          ),
          filled: true,
          fillColor: _ctrl[index].text.isNotEmpty
              ? const Color(0xFFE8F5E9)
              : Colors.white,
        ),
        onChanged: (val) {
          setState(() {});
          _onDigitChanged(val, index);
        },
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length < 5) return phone;
    final visible = phone.substring(phone.length - 4);
    return '${phone.substring(0, phone.length - 8)}****$visible';
  }
}
