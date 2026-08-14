import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EditDonorProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditDonorProfileScreen({super.key, required this.user});

  @override
  State<EditDonorProfileScreen> createState() => _EditDonorProfileScreenState();
}

class _EditDonorProfileScreenState extends State<EditDonorProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.user['name'] ?? '';
    _emailCtrl.text = widget.user['email'] ?? '';
    _phoneCtrl.text = widget.user['phoneNumber'] ?? '';
    _addressCtrl.text = widget.user['address']?['formattedAddress'] ?? 'Pune, Maharashtra';
    _photoUrlCtrl.text = widget.user['profilePhotoUrl'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final res = await ApiService.patch('/donor/profile', {
        'donorId': widget.user['_id'],
        'name': _nameCtrl.text,
        'email': _emailCtrl.text,
        'phoneNumber': _phoneCtrl.text,
        'address': _addressCtrl.text,
        'profilePhotoUrl': _photoUrlCtrl.text,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] ?? {};
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('🎉 Donor Profile & Details updated successfully!'),
          ),
        );
        Navigator.pop(context, data);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update Donor Profile.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile update error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _photoUrlCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Donor Account & Profile'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green.shade100,
                  backgroundImage: photoUrl.startsWith('http') ? NetworkImage(photoUrl) : null,
                  child: !photoUrl.startsWith('http')
                      ? const Icon(Icons.person, size: 50, color: Colors.green)
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 18, color: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Pickup Location Address *',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email Address *',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Contact Phone Number *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _photoUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Profile Photo URL',
                prefixIcon: Icon(Icons.photo_camera),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Save Profile & Account Details',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: _isSaving ? null : _saveProfile,
            )
          ],
        ),
      ),
    );
  }
}
