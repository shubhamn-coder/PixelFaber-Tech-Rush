import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';

class QrCollectionModal extends StatefulWidget {
  final String donationId;
  final String verificationCode;
  final String itemTitle;
  final bool isNgo;

  const QrCollectionModal({
    super.key,
    required this.donationId,
    required this.verificationCode,
    required this.itemTitle,
    required this.isNgo,
  });

  static void show(
    BuildContext context, {
    required String donationId,
    required String verificationCode,
    required String itemTitle,
    required bool isNgo,
    VoidCallback? onCollectionVerified,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => QrCollectionModal(
        donationId: donationId,
        verificationCode: verificationCode,
        itemTitle: itemTitle,
        isNgo: isNgo,
      ),
    ).then((_) => onCollectionVerified?.call());
  }

  @override
  State<QrCollectionModal> createState() => _QrCollectionModalState();
}

class _QrCollectionModalState extends State<QrCollectionModal> {
  final _codeCtrl = TextEditingController();
  bool _isVerifying = false;

  Future<void> _verifyCode([String? inputCode]) async {
    final code = (inputCode ?? _codeCtrl.text).trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or scan the 6-digit passcode.')),
      );
      return;
    }
    setState(() => _isVerifying = true);

    try {
      final res = await ApiService.post(
        '/donations/${widget.donationId}/verify-collection',
        {'code': code},
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('🎉 Passcode matched! Pickup completed & moved to Impact History!'),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('❌ Invalid verification code! Please check code from NGO volunteer.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _simulateQrScan() {
    _codeCtrl.text = widget.verificationCode;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.teal,
        content: Text('📷 QR Code Scanned Successfully! Auto-verifying passcode...'),
      ),
    );
    _verifyCode(widget.verificationCode);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.isNgo
                  ? '🏢 NGO Doorstep Pickup Pass'
                  : '🔑 Confirm Doorstep Pickup Handover',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Item: ${widget.itemTitle}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
            ),
            const Divider(height: 20),

            // VIEW 1: NGO SEES QR CODE & 6-DIGIT CODE
            if (widget.isNgo) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade400, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade100,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: widget.verificationCode,
                  version: QrVersions.auto,
                  size: 170.0,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  children: [
                    const Text('Passcode for Donor:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      widget.verificationCode,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Show this QR code or tell this 6-digit passcode to the donor during physical pickup.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],

            // VIEW 2: DONOR SEES QR SCANNER BUTTON & 6-DIGIT CODE TYPING BOX
            if (!widget.isNgo) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade800,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                      label: const Text(
                        '📷 Scan NGO QR Code',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _simulateQrScan,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('— OR TYPE MANUALLY BELOW —', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    TextField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 6),
                      decoration: InputDecoration(
                        hintText: '• • • • • •',
                        labelText: 'Enter 6-Digit Code Told by NGO',
                        counterText: '',
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.teal),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  backgroundColor: Colors.green.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  'Confirm & Complete Pickup',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _isVerifying ? null : () => _verifyCode(),
              ),
            ],

            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close Modal'),
            )
          ],
        ),
      ),
    );
  }
}
