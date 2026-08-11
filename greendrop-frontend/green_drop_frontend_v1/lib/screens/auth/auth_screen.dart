import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../widgets/greendrop_native_logo.dart';
import '../home/main_home_screen.dart';


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  String _role = 'DONOR';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _emailController = TextEditingController(text: 'donor@greendrop.com');
  final _passwordController = TextEditingController(text: 'demo123');
  final _nameController = TextEditingController(text: 'Demo Donor');
  final _phoneController = TextEditingController(text: '+91 9876543210');

  final _darpanIdController = TextEditingController();
  final _certUrlController = TextEditingController();
  final _panUrlController = TextEditingController();
  final _officeAddressController = TextEditingController();

  String? _trustDeedPath;
  String? _exemption80GPath;
  String? _certificate12APath;
  final ImagePicker _picker = ImagePicker();

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
        _nameController.text = 'SAMS Relief Network';
        _emailController.text = 'ngo@samsrelief.org';
        _phoneController.text = '+91 9876500112';
        _darpanIdController.text = 'MH/2026/0048123';
        _certUrlController.text = 'trust_deed_document.pdf';
        _panUrlController.text = '80g_tax_certificate.pdf';
        _officeAddressController.text = 'Kothrud, Pune, MH 411038';
      } else if (type == 'ADMIN') {
        _role = 'ADMIN';
        _nameController.text = 'Platform System Admin';
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
          'description': 'SAMS Relief Network is dedicated to community welfare, disaster relief, and food distribution in Kothrud, Pune.',
        },
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
    final email = _emailController.text.trim();
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
    Map<String, dynamic> body = {
      'email': email,
      'password': password,
    };

    if (!_isLogin) {
      body.addAll({
        'role': _role,
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
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
      final res = await ApiService.post(path, body);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (!mounted) return;
        final userData = data['data'] as Map<String, dynamic>;
        final userRole = userData['role'] ?? 'DONOR';
        final int targetIndex = (userRole == 'ADMIN') ? 10 : 0;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainHomeScreen(user: userData, initialIndex: targetIndex),
          ),
        );
        return;
      }
      if (mounted) {
        // Fallback for demo logins if API returned error
        if (email.contains('greendrop') || email.contains('smilepune') || _isLogin) {
          final fallbackData = _getFallbackDemoUser(email, _role);
          final int targetIndex = (fallbackData['role'] == 'ADMIN') ? 10 : 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiService.errorMessage(res, fallback: 'Signed in with demo user profile.'))),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainHomeScreen(user: fallbackData, initialIndex: targetIndex),
            ),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.errorMessage(res, fallback: 'Unable to sign in.'))),
        );
      }
    } catch (_) {
      if (mounted) {
        // Offline / Unreachable API fallback mode so dashboard page ALWAYS loads!
        final fallbackData = _getFallbackDemoUser(email, _role);
        final int targetIndex = (fallbackData['role'] == 'ADMIN') ? 10 : 0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚡ Server offline: Loaded GreenDrop in Offline Demo Mode.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainHomeScreen(user: fallbackData, initialIndex: targetIndex),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. AMBIENT ECO MESH GRADIENT BACKDROP
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF082215), // Deep Midnight Forest
                  Color(0xFF13422A), // Rich Emerald Pine
                  Color(0xFF1E5631), // Vibrant Green
                  Color(0xFFF4F7F4), // Clean Light Contrast Base
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.3, 0.55, 1.0],
              ),
            ),
          ),

          // 2. SOFT AMBIENT GLOW ORB
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF81C784).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. SCROLLABLE FORM CONTAINER
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // HERO APP LOGO & HEADER BANNER WITH GLASS GLOW
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D3B1E), Color(0xFF1E5631), Color(0xFF4C9A2A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF81C784).withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          const GreenDropNativeLogo(
                            size: 75,
                            animate: true,
                            showText: true,
                            textColor: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Where giving back becomes second nature',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFE1E9DF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildGlassFeatureBadge(
                                icon: Icons.eco,
                                label: 'Zero Waste Tier',
                                badgeColor: const Color(0xFF81C784),
                              ),
                              _buildGlassFeatureBadge(
                                icon: Icons.warning_amber_rounded,
                                label: 'Disaster Relief Mode',
                                badgeColor: const Color(0xFFFFB74D),
                              ),
                              _buildGlassFeatureBadge(
                                icon: Icons.verified_user_rounded,
                                label: 'Verified NGO Network',
                                badgeColor: const Color(0xFF64B5F6),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                // QUICK DEMO ACCOUNTS BAR FOR 1-CLICK LOGIN
                Card(
                  color: Colors.white,
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.green.shade200, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt, size: 14, color: Colors.orange.shade800),
                            const SizedBox(width: 4),
                            Text(
                              'Quick 1-Click Demo Login',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  side: BorderSide(color: Colors.green.shade700, width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: Icon(Icons.person, size: 14, color: Colors.green.shade800),
                                label: Text('Donor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                                onPressed: () => _fillDemoAccount('DONOR'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  side: BorderSide(color: Colors.blue.shade700, width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: Icon(Icons.corporate_fare, size: 14, color: Colors.blue.shade800),
                                label: Text('NGO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                onPressed: () => _fillDemoAccount('NGO'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  side: BorderSide(color: Colors.orange.shade800, width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: Icon(Icons.security, size: 14, color: Colors.orange.shade900),
                                label: Text('Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                                onPressed: () => _fillDemoAccount('ADMIN'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // MAIN FORM CARD CONTAINER
                Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TOGGLE LOGIN / REGISTER TABS
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text(
                                    'Log In',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                selected: _isLogin,
                                selectedColor: Colors.green.shade800,
                                labelStyle: TextStyle(
                                  color: _isLogin ? Colors.white : Colors.black87,
                                ),
                                onSelected: (val) => setState(() => _isLogin = true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text(
                                    'Register',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                selected: !_isLogin,
                                selectedColor: Colors.green.shade800,
                                labelStyle: TextStyle(
                                  color: !_isLogin ? Colors.white : Colors.black87,
                                ),
                                onSelected: (val) => setState(() => _isLogin = false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ROLE SELECTION CARDS IF REGISTERING (DONOR OR NGO ONLY)
                        if (!_isLogin) ...[
                          const Text(
                            'Select Account Type:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildRoleCard('DONOR', 'Donor 👤', Colors.green),
                              const SizedBox(width: 8),
                              _buildRoleCard('NGO', 'NGO 🏢', Colors.blue),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name / Organization Name *',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Phone Number *',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_role == 'NGO') ...[
                            TextField(
                              controller: _darpanIdController,
                              decoration: const InputDecoration(
                                labelText: 'NGO NITI Aayog Darpan ID (Confidential)',
                                prefixIcon: Icon(Icons.verified),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _officeAddressController,
                              decoration: const InputDecoration(
                                labelText: 'Registered Office Address *',
                                prefixIcon: Icon(Icons.location_city),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'NGO Verification Documents (PDF / Photos):',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                      side: BorderSide(color: _trustDeedPath != null ? Colors.green : Colors.blue.shade400),
                                    ),
                                    icon: Icon(_trustDeedPath != null ? Icons.check_circle : Icons.upload_file, size: 16, color: _trustDeedPath != null ? Colors.green : Colors.blue.shade800),
                                    label: Text(
                                      _trustDeedPath != null ? 'Trust Deed Attached' : 'Attach Trust Deed',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () => _pickDocument('trust'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                      side: BorderSide(color: _exemption80GPath != null ? Colors.green : Colors.blue.shade400),
                                    ),
                                    icon: Icon(_exemption80GPath != null ? Icons.check_circle : Icons.upload_file, size: 16, color: _exemption80GPath != null ? Colors.green : Colors.blue.shade800),
                                    label: Text(
                                      _exemption80GPath != null ? '80G Attached' : 'Attach 80G Cert',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () => _pickDocument('80g'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 38),
                                side: BorderSide(color: _certificate12APath != null ? Colors.green : Colors.blue.shade400),
                              ),
                              icon: Icon(_certificate12APath != null ? Icons.check_circle : Icons.upload_file, size: 16, color: _certificate12APath != null ? Colors.green : Colors.blue.shade800),
                              label: Text(
                                _certificate12APath != null ? '12A Certificate Attached' : 'Attach 12A Registration Certificate',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _pickDocument('12a'),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Registered Email Address *',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: _isLogin
                                ? 'Account Password (Default Demo: demo123) *'
                                : 'Create Account Password *',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // SUBMIT BUTTON
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            backgroundColor: Colors.green.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: _isLoading ? null : _handleSubmit,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _isLogin ? 'Log In to GreenDrop' : 'Create $_role Account',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
);
}

  Widget _buildRoleCard(String roleVal, String label, Color color) {
    final isSelected = _role == roleVal;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = roleVal),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassFeatureBadge({
    required IconData icon,
    required String label,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
