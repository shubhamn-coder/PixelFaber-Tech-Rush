import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../widgets/greendrop_native_logo.dart';
import '../home/main_home_screen.dart';
import 'phone_otp_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  String _role = 'DONOR';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  // Phone OTP verification state
  String? _phoneVerifyToken; // non-null means phone has been verified

  final _emailController    = TextEditingController(text: 'donor@greendrop.com');
  final _passwordController = TextEditingController(text: 'demo123');
  final _nameController     = TextEditingController(text: 'Demo Donor');
  final _phoneController    = TextEditingController(text: '+91 9876543210');

  final _darpanIdController      = TextEditingController();
  final _certUrlController       = TextEditingController();
  final _panUrlController        = TextEditingController();
  final _officeAddressController = TextEditingController();

  String? _trustDeedPath;
  String? _exemption80GPath;
  String? _certificate12APath;
  final ImagePicker _picker = ImagePicker();

  // ─────────── colour tokens ───────────
  static const _dark1 = Color(0xFF082215);
  static const _dark2 = Color(0xFF13422A);
  static const _green = Color(0xFF1E5631);
  static const _white = Colors.white;

  Future<void> _pickDocument(String type) async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        if (type == 'trust') {
          _trustDeedPath = file.path;
          _certUrlController.text = file.name;
        } else if (type == '80g') {
          _exemption80GPath = file.path;
          _panUrlController.text = file.name;
        } else if (type == '12a') {
          _certificate12APath = file.path;
        }
      });
    }
  }

  void _fillDemoAccount(String type) {
    setState(() {
      _passwordController.text = 'demo123';
      if (type == 'DONOR') {
        _role = 'DONOR';
        _nameController.text = 'Demo Donor';
        _emailController.text = 'donor@greendrop.com';
        _phoneController.text = '+91 9876543210';
      } else if (type == 'NGO') {
        _role = 'NGO';
        _nameController.text  = 'SAMS Relief Network';
        _emailController.text = 'ngo@samsrelief.org';
        _phoneController.text = '+91 9876500112';
        _darpanIdController.text     = 'MH/2026/0048123';
        _certUrlController.text      = 'trust_deed_document.pdf';
        _panUrlController.text       = '80g_tax_certificate.pdf';
        _officeAddressController.text = 'Kothrud, Pune, MH 411038';
      } else if (type == 'ADMIN') {
        _role = 'ADMIN';
        _nameController.text  = 'Platform System Admin';
        _emailController.text = 'admin@greendrop.org';
        _phoneController.text = '+91 0000000000';
      }
    });
  }

  Map<String, dynamic> _getFallbackDemoUser(String email, String role) {
    if (email.contains('admin') || role == 'ADMIN') {
      return {
        '_id': 'demo_admin_001',
        'name': 'Platform System Admin',
        'email': 'admin@greendrop.org',
        'role': 'ADMIN',
        'phoneNumber': '+91 0000000000',
      };
    } else if (email.contains('ngo') || email.contains('sams') || role == 'NGO') {
      return {
        '_id': 'demo_ngo_001',
        'name': 'SAMS Relief Network',
        'email': 'ngo@samsrelief.org',
        'role': 'NGO',
        'phoneNumber': '+91 9876500112',
        'ngoDetails': {
          'darpanId': 'MH/2026/0048123',
          'officeAddress': 'Kothrud, Pune, MH 411038',
          'isVerified': true,
          'description':
              'SAMS Relief Network is dedicated to community welfare, disaster relief, and food distribution in Kothrud, Pune.',
        },
      };
    } else if (email.contains('recycle') || role == 'RECYCLER') {
      return {
        '_id': 'demo_recycler_001',
        'name': 'EcoGreen Upcyclers',
        'email': email.isNotEmpty ? email : 'recycler@greendrop.org',
        'role': 'RECYCLER',
        'phoneNumber': '+91 9988776655',
      };
    } else {
      return {
        '_id': 'demo_donor_001',
        'name': 'Demo Donor',
        'email': email.isNotEmpty ? email : 'donor@greendrop.com',
        'role': 'DONOR',
        'phoneNumber': '+91 9876543210',
      };
    }
  }

  Future<void> _handleSubmit() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your account password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final path = _isLogin ? '/auth/login' : '/auth/register';
    Map<String, dynamic> body = {'email': email, 'password': password};

    if (!_isLogin) {
      body.addAll({
        'role': _role,
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        if (_phoneVerifyToken != null) 'phoneVerifyToken': _phoneVerifyToken,
      });
      if (_role == 'NGO') {
        body['ngoDetails'] = {
          'darpanId': _darpanIdController.text.trim(),
          'registrationCertificateUrl': _certUrlController.text.trim(),
          'panCardUrl': _panUrlController.text.trim(),
          'officeAddress': _officeAddressController.text.trim(),
        };
      }
    }

    try {
      final res  = await ApiService.post(path, body);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (!mounted) return;
        final userData = data['data'] as Map<String, dynamic>;
        final userRole = userData['role'] ?? 'DONOR';
        final int targetIndex = (userRole == 'ADMIN') ? 10 : 0;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MainHomeScreen(user: userData, initialIndex: targetIndex),
          ),
        );
        return;
      }
      if (mounted) {
        if (email.contains('greendrop') || email.contains('smilepune') || _isLogin) {
          final fallbackData = _getFallbackDemoUser(email, _role);
          final int targetIndex = (fallbackData['role'] == 'ADMIN') ? 10 : 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(ApiService.errorMessage(res,
                    fallback: 'Signed in with demo user profile.'))),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MainHomeScreen(user: fallbackData, initialIndex: targetIndex),
            ),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  ApiService.errorMessage(res, fallback: 'Unable to sign in.'))),
        );
      }
    } catch (_) {
      if (mounted) {
        final fallbackData = _getFallbackDemoUser(email, _role);
        final int targetIndex = (fallbackData['role'] == 'ADMIN') ? 10 : 0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('⚡ Server offline: Loaded GreenDrop in Offline Demo Mode.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MainHomeScreen(user: fallbackData, initialIndex: targetIndex),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _darpanIdController.dispose();
    _certUrlController.dispose();
    _panUrlController.dispose();
    _officeAddressController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── full-screen gradient background ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_dark1, _dark2, _green, Color(0xFFF0F4F0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.28, 0.52, 1.0],
              ),
            ),
          ),

          // ── ambient glow top-right ──
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF81C784).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── scrollable content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      _buildHeroBanner(),
                      const SizedBox(height: 16),
                      _buildDemoBar(),
                      const SizedBox(height: 16),
                      _buildFormCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  SECTION 1 — Hero banner (dark green card with logo + chips)
  // ════════════════════════════════════════════════════════════
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C3320), Color(0xFF1B5E38), Color(0xFF2E7D52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: const Color(0xFF81C784).withValues(alpha: 0.28), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── logo ──
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E38),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: const Color(0xFF81C784).withValues(alpha: 0.5),
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const GreenDropNativeLogo(
              size: 48,
              animate: true,
              showText: false,
            ),
          ),
          const SizedBox(height: 10),

          // ── app name ──
          const Text(
            'GreenDrop',
            style: TextStyle(
              color: _white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),

          // ── tagline pill ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Where giving back becomes second nature',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFDCF0DC),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── feature chips ──
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _featureChip(Icons.eco_rounded,         'Zero Waste Network',  const Color(0xFF81C784)),
              _featureChip(Icons.warning_amber_rounded, 'Disaster Relief',   const Color(0xFFFFB74D)),
              _featureChip(Icons.verified_user_rounded, 'Verified NGO Hub',  const Color(0xFF64B5F6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.65), width: 1.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  SECTION 2 — Quick demo bar
  // ════════════════════════════════════════════════════════════
  Widget _buildDemoBar() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt, size: 14, color: Colors.orange.shade700),
              const SizedBox(width: 4),
              Text(
                'QUICK 1-CLICK DEMO LOGIN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _demoBtn('Donor 👤',  Colors.green.shade700,  'DONOR'),
              const SizedBox(width: 8),
              _demoBtn('NGO 🏢',    Colors.blue.shade700,   'NGO'),
              const SizedBox(width: 8),
              _demoBtn('Admin ❤️',  Colors.orange.shade800, 'ADMIN'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _demoBtn(String label, Color color, String role) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 7),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: color, width: 1.3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _fillDemoAccount(role),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  SECTION 3 — Main form card
  // ════════════════════════════════════════════════════════════
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── pill toggle tabs ──
          _buildToggleTabs(),
          const SizedBox(height: 20),

          // ── welcome text ──
          Text(
            _isLogin ? 'Welcome to GreenDrop 👋' : 'Create an Account 🌱',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isLogin
                ? 'Sign in to access your donation dashboard, verified drives & relief tracking.'
                : 'Join GreenDrop and start making a difference today.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 20),

          const SizedBox(height: 14),
          _sectionLabel(_isLogin ? 'Login Role:' : 'Account Type:'),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRoleCard('DONOR', 'Donor 👤', Colors.green),
              const SizedBox(width: 6),
              _buildRoleCard('NGO', 'NGO 🏢', Colors.blue),
              const SizedBox(width: 6),
              _buildRoleCard('RECYCLER', 'Recycler ♻️', Colors.teal),
            ],
          ),
          const SizedBox(height: 14),
          if (!_isLogin) ...[
            _buildField(
              controller: _nameController,
              label: 'Full Name / Organization Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            // ── Phone field + Verify button ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildField(
                    controller: _phoneController,
                    label: 'Contact Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    suffixIcon: _phoneVerifyToken != null
                        ? const Icon(Icons.verified_rounded,
                            color: Color(0xFF2E7D32), size: 20)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _phoneVerifyToken != null
                          ? const Color(0xFF2E7D32)
                          : Colors.white,
                      foregroundColor: _phoneVerifyToken != null
                          ? Colors.white
                          : const Color(0xFF2E7D32),
                      elevation: 0,
                      side: const BorderSide(
                          color: Color(0xFF2E7D32), width: 1.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: _phoneVerifyToken != null
                        ? null
                        : () async {
                            final phone = _phoneController.text.trim();
                            if (phone.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please enter your phone number first.')),
                              );
                              return;
                            }
                            final token = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PhoneOtpScreen(phoneNumber: phone),
                              ),
                            );
                            if (token != null) {
                              setState(() => _phoneVerifyToken = token);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Color(0xFF2E7D32),
                                    content: Text(
                                        '✅ Phone verified successfully!'),
                                  ),
                                );
                              }
                            }
                          },
                    child: _phoneVerifyToken != null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_rounded, size: 18),
                              Text('Verified',
                                  style: TextStyle(fontSize: 10)),
                            ],
                          )
                        : const Text(
                            'Verify\nPhone',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_role == 'NGO') ...[
              _buildField(
                controller: _darpanIdController,
                label: 'NGO NITI Aayog Darpan ID',
                icon: Icons.verified_outlined,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _officeAddressController,
                label: 'Registered Office Address',
                icon: Icons.location_city_outlined,
              ),
              const SizedBox(height: 12),
              _sectionLabel('NGO Verification Documents:'),
              const SizedBox(height: 6),
              Row(
                children: [
                  _uploadBtn('Attach Trust Deed', 'Trust Deed ✓', _trustDeedPath, () => _pickDocument('trust')),
                  const SizedBox(width: 8),
                  _uploadBtn('Attach 80G Cert',   '80G Attached ✓', _exemption80GPath, () => _pickDocument('80g')),
                ],
              ),
              const SizedBox(height: 8),
              _uploadBtn('Attach 12A Registration Certificate', '12A Attached ✓',
                  _certificate12APath, () => _pickDocument('12a'), full: true),
              const SizedBox(height: 14),
            ],
          ],

          // ── email field ──
          _sectionLabel('Email Address *'),
          const SizedBox(height: 6),
          _buildField(
            controller: _emailController,
            label: 'donor@greendrop.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            floatingLabel: false,
          ),
          const SizedBox(height: 14),

          // ── password field ──
          _sectionLabel('Password *'),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: const TextStyle(fontSize: 18, letterSpacing: 3),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.lock_outline, size: 20, color: Color(0xFF4CAF50)),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD8D8D8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF4CAF50), width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── remember me + forgot password ──
          if (_isLogin)
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Remember me',
                    style: TextStyle(fontSize: 13, color: Color(0xFF444444))),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD4A017),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // ── CTA button ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: _white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: _white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin
                              ? 'Log In to GreenDrop'
                              : 'Create $_role Account',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── pill toggle tabs ───
  Widget _buildToggleTabs() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tabOption(label: '↩ Log In',    isActive: _isLogin,  onTap: () => setState(() => _isLogin = true)),
          _tabOption(label: '👤 Register', isActive: !_isLogin, onTap: () => setState(() => _isLogin = false)),
        ],
      ),
    );
  }

  Widget _tabOption(
      {required String label,
      required bool isActive,
      required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2E7D32) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isActive ? _white : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }

  // ─── helper widgets ───
  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF222222),
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool floatingLabel = true,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: floatingLabel ? label : null,
        hintText: floatingLabel ? null : label,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 20, color: const Color(0xFF4CAF50)),
        ),
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD8D8D8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF4CAF50), width: 1.6),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String roleVal, String label, Color color) {
    final isSelected = _role == roleVal;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = roleVal),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFDDDDDD),
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : const Color(0xFF555555),
            ),
          ),
        ),
      ),
    );
  }

  Widget _uploadBtn(
      String empty, String filled, String? path, VoidCallback onTap,
      {bool full = false}) {
    final attached = path != null;
    final btn = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        minimumSize: full ? const Size(double.infinity, 38) : Size.zero,
        side: BorderSide(
            color: attached ? Colors.green : Colors.blue.shade400),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(
        attached ? Icons.check_circle : Icons.upload_file,
        size: 15,
        color: attached ? Colors.green : Colors.blue.shade700,
      ),
      label: Text(
        attached ? filled : empty,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      onPressed: onTap,
    );
    return full ? btn : Expanded(child: btn);
  }
}
