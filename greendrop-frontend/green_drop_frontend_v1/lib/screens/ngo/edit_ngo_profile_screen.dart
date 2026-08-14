import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class EditNgoProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditNgoProfileScreen({super.key, required this.user});

  @override
  State<EditNgoProfileScreen> createState() => _EditNgoProfileScreenState();
}

class _EditNgoProfileScreenState extends State<EditNgoProfileScreen> {
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = widget.user['phoneNumber'] ?? '';
    _photoUrlCtrl.text = widget.user['profilePhotoUrl'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';
    final ngo = widget.user['ngoDetails'];
    if (ngo != null) {
      _descCtrl.text = ngo['description'] ?? 'Empowering communities through transparent relief.';
      _addressCtrl.text = ngo['officeAddress'] ?? 'FC Road, Deccan Gymkhana, Pune, MH 411004';
      _websiteCtrl.text = ngo['websiteUrl'] ?? 'https://smilefoundationindia.org';
      _linkedinCtrl.text = ngo['linkedinUrl'] ?? 'https://linkedin.com/company/smile-foundation';
      _instagramCtrl.text = ngo['instagramUrl'] ?? 'https://instagram.com/smilefoundationindia';
      _facebookCtrl.text = ngo['facebookUrl'] ?? 'https://facebook.com/smilefoundationindia';
      _youtubeCtrl.text = ngo['youtubeUrl'] ?? 'https://youtube.com/@smilefoundation';
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final res = await ApiService.patch('/ngo/profile', {
        'ngoId': widget.user['_id'],
        'description': _descCtrl.text,
        'officeAddress': _addressCtrl.text,
        'phoneNumber': _phoneCtrl.text,
        'websiteUrl': _websiteCtrl.text,
        'linkedinUrl': _linkedinCtrl.text,
        'instagramUrl': _instagramCtrl.text,
        'facebookUrl': _facebookCtrl.text,
        'youtubeUrl': _youtubeCtrl.text,
        'profilePhotoUrl': _photoUrlCtrl.text,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] ?? {};
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('🎉 NGO Public Profile updated successfully!'),
          ),
        );
        Navigator.pop(context, data);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update NGO Profile.'),
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
        title: const Text('Edit NGO Public Profile'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.green.shade100,
                    backgroundImage: photoUrl.startsWith('data:image')
                        ? MemoryImage(base64Decode(photoUrl.split(',').last))
                        : photoUrl.startsWith('http')
                            ? NetworkImage(photoUrl) as ImageProvider
                            : null,
                    child: (!photoUrl.startsWith('http') && !photoUrl.startsWith('data:image'))
                        ? const Icon(Icons.corporate_fare, size: 46, color: Colors.green)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _photoUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'NGO Logo / Profile Photo URL (or pick from device)',
                prefixIcon: Icon(Icons.photo_camera),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 42),
                side: BorderSide(color: Colors.green.shade800),
              ),
              icon: const Icon(Icons.photo_library, color: Colors.green),
              label: const Text('🖼️ Select Logo Image from Device Gallery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () async {
                try {
                  final picker = ImagePicker();
                  final XFile? img = await picker.pickImage(source: ImageSource.gallery);
                  if (img != null) {
                    final bytes = await img.readAsBytes();
                    setState(() {
                      _photoUrlCtrl.text = 'data:image/png;base64,${base64Encode(bytes)}';
                    });
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text('✅ NGO logo loaded from device gallery!'),
                      ),
                    );
                  }
                } catch (_) {}
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'About NGO & Mission Statement *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Registered Office Headquarters Address *',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Official Contact Phone Number *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _websiteCtrl,
              decoration: const InputDecoration(
                labelText: 'Official NGO Website URL',
                prefixIcon: Icon(Icons.language),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkedinCtrl,
              decoration: const InputDecoration(
                labelText: 'LinkedIn Profile / Page URL',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instagramCtrl,
              decoration: const InputDecoration(
                labelText: 'Instagram Handle / Page URL',
                prefixIcon: Icon(Icons.camera_alt),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _facebookCtrl,
              decoration: const InputDecoration(
                labelText: 'Facebook Page URL',
                prefixIcon: Icon(Icons.facebook),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _youtubeCtrl,
              decoration: const InputDecoration(
                labelText: 'YouTube Channel / Video URL',
                prefixIcon: Icon(Icons.play_circle_fill),
                border: OutlineInputBorder(),
              ),
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
                'Save NGO Profile Changes',
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
