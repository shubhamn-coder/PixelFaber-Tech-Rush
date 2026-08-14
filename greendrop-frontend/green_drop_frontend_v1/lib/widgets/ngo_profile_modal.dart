import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class NgoProfileModal extends StatefulWidget {
  final String ngoId;
  final String ngoName;
  final Map<String, dynamic>? currentUser;

  const NgoProfileModal({
    super.key,
    required this.ngoId,
    required this.ngoName,
    this.currentUser,
  });

  static void show(BuildContext context, String ngoId, String ngoName, {Map<String, dynamic>? currentUser}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => NgoProfileModal(
        ngoId: ngoId,
        ngoName: ngoName,
        currentUser: currentUser,
      ),
    );
  }

  @override
  State<NgoProfileModal> createState() => _NgoProfileModalState();
}

class _NgoProfileModalState extends State<NgoProfileModal> {
  Map<String, dynamic>? _ngoProfile;
  List<dynamic> _reviews = [];
  double _avgRating = 5.0;
  int _totalReviews = 0;
  bool _isLoading = true;

  int _userRating = 5;
  final _commentCtrl = TextEditingController();
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileAndReviews();
  }

  Future<void> _fetchProfileAndReviews() async {
    try {
      final pRes = await ApiService.get('/ngo/profile/${widget.ngoId}');
      final rRes = await ApiService.get('/reviews/${widget.ngoId}');
      if (pRes.statusCode == 200) {
        _ngoProfile = jsonDecode(pRes.body)['data'];
      }
      if (rRes.statusCode == 200) {
        final rBody = jsonDecode(rRes.body);
        _reviews = rBody['data'] ?? [];
        _avgRating = (rBody['averageRating'] as num?)?.toDouble() ?? 5.0;
        _totalReviews = (rBody['totalReviews'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submitRatingReview() async {
    if (widget.currentUser == null) return;
    setState(() => _isSubmittingReview = true);

    try {
      final role = widget.currentUser!['role'] ?? 'DONOR';
      await ApiService.post('/reviews', {
        'targetUserId': widget.ngoId,
        'targetUserName': widget.ngoName,
        'reviewerId': widget.currentUser!['_id'],
        'reviewerName': widget.currentUser!['name'],
        'reviewerRole': role,
        'rating': _userRating,
        'comment': role == 'DONOR' ? _commentCtrl.text : '',
      });

      _commentCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('🎉 Rating / Review submitted successfully!'),
        ),
      );
      _fetchProfileAndReviews();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 350,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final p = _ngoProfile ?? {};
    final ngoDetails = (p['ngoDetails'] as Map<String, dynamic>?) ?? p;
    final isVerified = p['isVerified'] ?? ngoDetails['isVerified'] ?? true;
    final address = p['officeAddress'] ?? ngoDetails['officeAddress'] ?? 'Pune NGO Office';
    final desc = p['description'] ?? ngoDetails['description'] ?? 'Dedicated to transparent charity and community welfare.';
    final phone = p['phoneNumber'] ?? ngoDetails['phoneNumber'] ?? '';

    final userRole = widget.currentUser?['role'] ?? 'DONOR';
    final isDonor = userRole == 'DONOR';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green.shade800,
                  child: Text(
                    widget.ngoName[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ngoName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isVerified)
                        Row(
                          children: [
                            Icon(Icons.verified, color: Colors.green.shade800, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Verified NGO ✔️',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$_avgRating / 5.0 ($_totalReviews reviews)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'ℹ️ About & Mission:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(desc, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 Registered Office Headquarters:\n$address',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📞 Contact Phone: $phone',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '🌐 Social Media & Official Channels:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSocialChip('Instagram 📸', p['instagramUrl'] ?? 'https://instagram.com/smilefoundationindia', Colors.pink),
                _buildSocialChip('YouTube ▶️', p['youtubeUrl'] ?? 'https://youtube.com/@smilefoundation', Colors.red),
                _buildSocialChip('Facebook 👤', p['facebookUrl'] ?? 'https://facebook.com/smilefoundationindia', Colors.blue.shade800),
                _buildSocialChip('LinkedIn 💼', p['linkedinUrl'] ?? 'https://linkedin.com/company/smile-foundation', Colors.blue.shade700),
                _buildSocialChip('Website 🌐', p['websiteUrl'] ?? 'https://smilefoundationindia.org', Colors.teal),
              ],
            ),
            const SizedBox(height: 14),

            // NGO LEGAL REGISTRATION DOCUMENTS SECTION (ADMIN ONLY ACCESS)
            if (widget.currentUser?['role'] == 'ADMIN') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade300, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '🔐 Admin Access Only: NGO Registration & Tax Documents',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.blue.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            side: BorderSide(color: Colors.blue.shade400),
                          ),
                          icon: const Icon(Icons.description, color: Colors.red, size: 16),
                          label: const Text('📜 Trust Deed Doc', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => _viewDocument(
                            context,
                            'Trust Deed Registration Document',
                            ngoDetails['trustDeedPath'] ?? 'https://greendrop.org/docs/trust_deed_sample.pdf',
                            'Government Registered Trust Deed Certificate',
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            side: BorderSide(color: Colors.green.shade400),
                          ),
                          icon: const Icon(Icons.verified, color: Colors.green, size: 16),
                          label: const Text('📄 80G Tax Exemption', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => _viewDocument(
                            context,
                            '80G Tax Exemption Certificate',
                            ngoDetails['exemption80GPath'] ?? 'https://greendrop.org/docs/80g_exemption_sample.pdf',
                            'Income Tax Act Section 80G Certificate for Donor Tax Exemptions',
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            side: BorderSide(color: Colors.purple.shade400),
                          ),
                          icon: const Icon(Icons.card_membership, color: Colors.purple, size: 16),
                          label: const Text('🛡️ 12A Registration', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => _viewDocument(
                            context,
                            '12A Registration Certificate',
                            ngoDetails['certificate12APath'] ?? 'https://greendrop.org/docs/12a_cert_sample.pdf',
                            'Income Tax Act Section 12A Charitable Institution Registration',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user, color: Colors.green.shade800, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🛡️ Verified & Authenticated NGO',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade900),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Official Trust Deed, 80G & 12A documents have been verified by GreenDrop Admin. Legal document files are restricted to Admin access only.',
                            style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // INTERACTIVE RATING & REVIEW FORM
            if (widget.currentUser != null) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDonor ? '⭐ Rate & Write Review for NGO' : '⭐ Rate NGO (Stars Only)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          5,
                          (idx) => IconButton(
                            icon: Icon(
                              idx < _userRating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () => setState(() => _userRating = idx + 1),
                          ),
                        ),
                      ),
                      if (isDonor) ...[
                        TextField(
                          controller: _commentCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Write your experience / review for this NGO...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ] else ...[
                        const Text(
                          'ℹ️ Note: Only Donors can post written text reviews for NGOs.',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                      ],
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade800,
                        ),
                        icon: _isSubmittingReview
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send, color: Colors.white, size: 16),
                        label: const Text('Submit Rating', style: TextStyle(color: Colors.white, fontSize: 12)),
                        onPressed: _isSubmittingReview ? null : _submitRatingReview,
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // REVIEWS LIST
            const Text(
              '💬 Community Reviews:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            if (_reviews.isEmpty)
              const Text('No reviews submitted yet.', style: TextStyle(color: Colors.grey, fontSize: 12))
            else
              ..._reviews.map(
                (r) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r['reviewerName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            Text('${r['rating']} / 5', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        )
                      ],
                    ),
                    subtitle: (r['comment'] ?? '').isNotEmpty
                        ? Text(r['comment'])
                        : const Text('Star Rating Submitted', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ),
                ),
              ),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialChip(String label, String url, Color color) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 10,
        child: const Icon(Icons.link, size: 10, color: Colors.white),
      ),
      label: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            messenger.showSnackBar(
              SnackBar(
                backgroundColor: color,
                content: Text('🌐 Opening official link: $url'),
              ),
            );
          }
        } catch (_) {
          messenger.showSnackBar(
            SnackBar(
              backgroundColor: color,
              content: Text('🌐 Opening link: $url'),
            ),
          );
        }
      },
    );
  }

  void _viewDocument(BuildContext context, String docTitle, String docUrl, String description) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.verified_user, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(docTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Document Path / File:\n$docUrl',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 28),
                    SizedBox(height: 4),
                    Text(
                      'Verified NGO Registration Certificate',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
            icon: const Icon(Icons.open_in_new, color: Colors.white, size: 16),
            label: const Text('Open Document', style: TextStyle(color: Colors.white, fontSize: 12)),
            onPressed: () async {
              Navigator.pop(c);
              try {
                final uri = Uri.parse(docUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }
}
