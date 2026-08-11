import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<Map<String, String>> _messages = [
    {
      'sender': 'bot',
      'text':
          '🤖 Welcome to GreenDrop Master AI Assistant!\n\nI am your 24/7 smart concierge. Ask me anything about 80G tax receipts, 2-way verification passcodes, Porter/Uber courier dispatch, MapmyIndia navigation, or disaster relief drives!'
    }
  ];

  final List<String> _quickPrompts = [
    '📜 How do 80G Tax Receipts work?',
    '🔐 What is the 2-Way Passcode Handshake?',
    '🚚 How to dispatch Porter or Uber Courier?',
    '🗺️ How to view NGO offices on MapmyIndia?',
    '🚨 How does Disaster Relief Ticker work?',
    '📄 How can Admin view NGO legal documents?',
    '📋 How to respond to NGO Demand Requests?',
  ];

  Widget _buildFormattedText(String text, bool isBot) {
    // Remove raw ** asterisks cleanly so no literal asterisks show on screen
    final cleanText = text.replaceAll('**', '').replaceAll('*', '•');
    return Text(
      cleanText,
      style: TextStyle(
        color: isBot ? Colors.black87 : Colors.white,
        fontSize: 13.5,
        height: 1.45,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleUserQuery(String text) async {
    if (text.trim().isEmpty) return;

    final userQuery = text.trim();
    setState(() {
      _messages.add({'sender': 'user', 'text': userQuery});
    });
    _scrollToBottom();

    // 1. Local fallback response
    String reply =
        "🤖 I am here to help solve every query! For specific account inquiries, feel free to reach our core support team at support@greendrop.org.";

    final q = userQuery.toLowerCase();

    if (q.contains('donor') || q.contains('how to use') || q.contains('guide') || q.contains('start') || q.contains('step') || q.contains('user')) {
      reply =
          "🙋 **How to Use GreenDrop as a Donor (Step-by-Step Guide)**:\n\n"
          "1. **Post a Donation**: Tap the green **'+'** button at the bottom right. Upload photos, enter item details (clothes, books, food, electronics), and your pickup address.\n"
          "2. **NGO Matching**: Verified local NGOs (like SAMS Relief Network) browse and request your item.\n"
          "3. **Accept Request**: Tap **'Accept Request'** on your item card to safely reveal your address to the NGO and open 1-on-1 chat.\n"
          "4. **2-Way Handshake at Pickup**: Tap **'QR Pass 🔑'** to see your 6-digit code. Show it to the NGO volunteer at your door. Once verified, tap **'Confirm & Complete Handover'**!\n"
          "5. **Tax Receipt & Impact**: Download your official **80G Tax Exemption PDF** and watch your CO₂ Environmental Points increase live under Profile!";
    } else if (q.contains('tax') || q.contains('80g') || q.contains('receipt') || q.contains('exemption') || q.contains('deduction') || q.contains('12a')) {
      reply =
          "📜 **80G Tax Receipts & Exemption Guidance**:\n\n• **For Donors**: Verified NGOs like SAMS Relief Network issue official 80G tax-deductible receipts for all contributions.\n• **How to Access**: Navigate to your **Profile / Impact History** tab after a donation handover is completed to download your official 80G Tax Exemption PDF receipt!";
    } else if (q.contains('courier') || q.contains('uber') || q.contains('porter') || q.contains('zepto') || q.contains('blinkit') || q.contains('dispatch') || q.contains('delivery')) {
      reply =
          "🚚 **On-Demand Courier Dispatch (Porter, Uber, Zepto, Blinkit)**:\n\n• **For NGOs**: If your NGO lacks a driver vehicle, tap **'📦 Use External Porter Service'** on the item card.\n• **Supported Providers**: Choose between Porter, Uber Connect, Zepto Express, or Blinkit Flash.\n• **Live Tracking**: Both Donor & NGO receive driver name, phone number, and live arrival ETA!";
    } else if (q.contains('qr') || q.contains('code') || q.contains('pass') || q.contains('verification') || q.contains('handshake') || q.contains('2-way')) {
      reply =
          "🔐 **2-Way Cryptographic Passcode Handshake**:\n\n1. **Passcode Generation**: Every claimed item generates a 6-digit verification code visible exclusively on the Donor's **'QR Pass 🔑'** button.\n2. **Volunteer Entry**: NGO volunteer types the donor's 6-digit code at doorstep collection.\n3. **Donor Final Confirmation**: Upon verification, donor taps green **'Confirm & Complete Handover'** button to complete transaction!";
    } else if (q.contains('map') || q.contains('mapmyindia') || q.contains('mappls') || q.contains('navigation') || q.contains('pin') || q.contains('route')) {
      reply =
          "🗺️ **In-App Interactive Map & Navigation**:\n\n• **Donor View**: Renders verified NGO Headquarters pins (SAMS Relief Network HQ in Kothrud, Pune).\n• **NGO View**: Renders accepted donor pickup markers & **Blue Polyline Driver Route Lines** connecting stops.\n• **In-App Pin Tapping**: Tap any pin to view address, contact phone, and route directions directly inside GreenDrop!";
    } else if (q.contains('disaster') || q.contains('emergency') || q.contains('relief') || q.contains('flood') || q.contains('earthquake') || q.contains('crisis') || q.contains('rescue') || q.contains('ticker') || q.contains('ration')) {
      reply =
          "🚨 **Emergency Disaster Relief Drives & Ticker**:\n\n• **NGO Emergency Activation**: NGOs facing crisis situations (floods, earthquakes, fires) toggle **Disaster Relief Mode**.\n• **Top 32px Emergency Ticker**: Broadcasts a high-priority 32px alert banner across the top of every donor screen.\n• **Immediate Supplies Matching**: Donors can instantly match critical emergency items (rations, blankets, medical kits, clean water) for priority volunteer pickup!";
    } else if (q.contains('admin') || q.contains('document') || q.contains('deed') || q.contains('proof') || q.contains('trust')) {
      reply =
          "📄 **Admin Registration Document Verification**:\n\n• **For Admins**: Go to the Admin Dashboard or tap any NGO Profile.\n• **Legal Documents**: View all 3 NGO registration attachments (**Trust Deed Document**, **80G Tax Certificate**, and **12A Certificate**) to verify authenticity!";
    } else if (q.contains('demand') || q.contains('requirement') || q.contains('need') || q.contains('delete')) {
      reply =
          "📋 **NGO Demand Board & Deletion**:\n\n• **For Donors**: View items requested by NGOs and tap **'🙋 I Want to Help'** to match specific items.\n• **For NGOs**: NGOs can post new demands or tap **'🗑️ Delete Requirement'** to remove fulfilled needs instantly!";
    } else if (q.contains('donate') || q.contains('post') || q.contains('item') || q.contains('add')) {
      reply =
          "📦 **How to Post a Donation**:\n\n1. Tap the green **'+'** floating button on the Home screen.\n2. Upload photos via camera or device gallery.\n3. Fill in item title, category, weight, and pickup address, then tap **'Post Donation'**!";
    } else if (q.contains('zero') || q.contains('waste') || q.contains('recycle') || q.contains('upcycle') || q.contains('earth')) {
      reply =
          "♻️ **Zero-Waste Upcycling Routing**:\n\nItems tagged as *'Fair / Worn Out'* bypass standard feeds and route to Certified Zero-Waste Upcycling Hubs (textiles, e-waste, plastics) to earn **Earth Guardian Badges**!";
    } else {
      reply =
          "🤖 **GreenDrop Master Guide**:\n\n"
          "• **Donors**: Tap **'+'** to list unused items (clothes, books, food, toys), accept NGO requests, get 80G tax receipts, and view live CO₂ impact!\n"
          "• **NGOs**: Browse donor items in Pune, request pickups, dispatch Porter/Uber couriers, and broadcast emergency disaster drives!\n"
          "• **Handshake Security**: Use 6-digit verification codes for 100% safe doorstep collection!";
    }

    // 2. Attempt live Gemini API call from backend
    try {
      final res = await ApiService.post('/chatbot/gemini', {'prompt': userQuery});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['reply'] != null && data['reply'].toString().isNotEmpty) {
          reply = data['reply'].toString();
        }
      }
    } catch (_) {
      // Clean silent fallback to expert local NLP engine if API key is not set
    }

    if (!mounted) return;
    setState(() => _messages.add({'sender': 'bot', 'text': reply}));
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // QUICK PROMPTS HORIZONTAL CAROUSEL
        Container(
          height: 48,
          color: Colors.green.shade50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            itemCount: _quickPrompts.length,
            itemBuilder: (c, i) {
              final prompt = _quickPrompts[i];
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: ActionChip(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.green.shade600),
                  label: Text(
                    prompt,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                  ),
                  onPressed: () => _handleUserQuery(prompt),
                ),
              );
            },
          ),
        ),

        // CHAT MESSAGES LIST
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (c, i) {
              final m = _messages[i];
              final isBot = m['sender'] == 'bot';
              return Align(
                alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isBot ? Colors.white : Colors.green.shade800,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: isBot ? Radius.zero : const Radius.circular(14),
                      bottomRight: isBot ? const Radius.circular(14) : Radius.zero,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                    border: isBot ? Border.all(color: Colors.green.shade300) : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isBot) ...[
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.green.shade800,
                          child: const Icon(Icons.smart_toy, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: _buildFormattedText(m['text'] ?? '', isBot),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // INPUT BAR
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (val) {
                    _handleUserQuery(val);
                    _ctrl.clear();
                  },
                  decoration: InputDecoration(
                    hintText: 'Ask GreenDrop Master AI Bot...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.green.shade800,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: () {
                    _handleUserQuery(_ctrl.text);
                    _ctrl.clear();
                  },
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
