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
    '📦 How do I post a food or clothes donation?',
    '📍 How do I track my donation pickup status?',
    '🟢 What items can I donate (Food, Clothes, Books)?',
    '🔒 Is my home address safe and private?',
    '🍃 How are my Green Points & CO₂ impact calculated?',
    '🗺️ How to view NGO offices on MapmyIndia?',
    '🚨 How does Disaster Relief Ticker work?',
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

  bool _isThinking = false;

  Future<void> _handleUserQuery(String text) async {
    if (text.trim().isEmpty || _isThinking) return;

    final userQuery = text.trim();
    setState(() {
      _messages.add({'sender': 'user', 'text': userQuery});
      _isThinking = true;
    });
    _scrollToBottom();

    final q = userQuery.toLowerCase();
    String reply = '';

    if (q.contains('track') || q.contains('pickup status') || q.contains('status')) {
      reply =
          "📍 **Tracking Your Donation Pickup Status**:\n\n"
          "• **Requested**: An NGO has requested your item. Tap **'Accept Request'** to approve.\n"
          "• **Accepted**: 1-on-1 chat opens with the NGO volunteer. You can view driver details or live ETA.\n"
          "• **Passcode Handshake**: Tap **'QR Pass 🔑'** to generate your 6-digit verification code for doorstep collection!";
    } else if (q.contains('what items') || q.contains('eligible') || q.contains('can i donate') || q.contains('category')) {
      reply =
          "🟢 **Eligible Donation Categories**:\n\n"
          "• **Food**: Fresh cooked meals, bakery items, surplus party food, unopened packaged rations & pulses.\n"
          "• **Clothing**: Clean winter jackets, sweaters, shoes, blankets, school uniforms.\n"
          "• **Books & Education**: Textbooks, storybooks, stationery, school supplies.\n"
          "• **Electronics & Household**: Working appliances, gadgets, toys, utensils.";
    } else if (q.contains('safe') || q.contains('private') || q.contains('privacy') || q.contains('address')) {
      reply =
          "🔒 **Address Privacy & Security**:\n\n"
          "• **Public Privacy**: Your exact street address is **never shown** on public feeds or search results.\n"
          "• **Selective Disclosure**: Your address is shared **only** with the specific verified NGO whose pickup request you explicitly accept!\n"
          "• **Doorstep Handshake**: Use your 6-digit verification code at collection for total security.";
    } else if (q.contains('point') || q.contains('co2') || q.contains('calculated') || q.contains('impact') || q.contains('reward')) {
      reply =
          "🍃 **Green CO₂ Impact & Reward Points**:\n\n"
          "• **CO₂ Saved**: Every kg of donated food saves ~2.5 kg CO₂; clothes save ~15 kg CO₂!\n"
          "• **Eco Badges**: Complete donations to earn **Earth Guardian** and **Zero-Waste Champion** badges.\n"
          "• **Impact Score**: View your live environmental dashboard under your Profile tab!";
    } else if (q.contains('post') || q.contains('donate') || q.contains('item') || q.contains('how do i post') || q.contains('add')) {
      reply =
          "📦 **How to Post a Donation (Step-by-Step)**:\n\n"
          "1. Tap the green **'+'** floating button on the Home screen.\n"
          "2. Upload photos of your unused clothes, cooked/raw food, books, or electronics.\n"
          "3. Fill in item title, category, weight, and pickup address, then tap **'Post Donation'**!\n"
          "4. Local verified NGOs will browse your listing and send a pickup request.";
    } else if (q.contains('donor') || q.contains('how to use') || q.contains('guide') || q.contains('start') || q.contains('step') || q.contains('user')) {
      reply =
          "🙋 **How to Use GreenDrop as a Donor (Step-by-Step Guide)**:\n\n"
          "1. **Post a Donation**: Tap the green **'+'** button at the bottom right. Upload photos, enter item details, and your pickup address.\n"
          "2. **NGO Matching**: Verified local NGOs browse and request your item.\n"
          "3. **Accept Request**: Tap **'Accept Request'** on your item card to safely reveal your address to the NGO.\n"
          "4. **2-Way Handshake at Pickup**: Tap **'QR Pass 🔑'** to see your 6-digit code. Show it to the volunteer at your door.\n"
          "5. **Tax Receipt & Impact**: Download your official **80G Tax Exemption PDF** and watch your CO₂ Points increase live!";
    } else if (q.contains('tax') || q.contains('80g') || q.contains('receipt') || q.contains('exemption') || q.contains('deduction')) {
      reply =
          "📜 **80G Tax Receipts & Exemption Guidance**:\n\n• **For Donors**: Verified NGOs issue official 80G tax-deductible receipts for all contributions.\n• **How to Access**: Navigate to your **Profile / Impact History** tab after a donation handover is completed to download your official 80G Tax Exemption PDF receipt!";
    } else if (q.contains('map') || q.contains('mapmyindia') || q.contains('mappls') || q.contains('navigation') || q.contains('pin') || q.contains('route')) {
      reply =
          "🗺️ **In-App Interactive Map & Navigation**:\n\n• **Donor View**: Renders verified NGO Headquarters pins (SAMS Relief Network HQ in Kothrud, Pune).\n• **NGO View**: Renders accepted donor pickup markers & **Blue Polyline Driver Route Lines** connecting stops.\n• **In-App Pin Tapping**: Tap any pin to view address, contact phone, and route directions directly inside GreenDrop!";
    } else if (q.contains('disaster') || q.contains('emergency') || q.contains('relief') || q.contains('flood') || q.contains('earthquake') || q.contains('crisis') || q.contains('rescue') || q.contains('ticker') || q.contains('ration')) {
      reply =
          "🚨 **Emergency Disaster Relief Drives & Ticker**:\n\n• **NGO Emergency Activation**: NGOs facing crisis situations toggle **Disaster Relief Mode**.\n• **Top 32px Emergency Ticker**: Broadcasts a high-priority 32px alert banner across the top of every donor screen.\n• **Immediate Supplies Matching**: Donors can instantly match critical emergency items (rations, blankets, medical kits, clean water) for priority volunteer pickup!";
    } else if (q.contains('demand') || q.contains('requirement') || q.contains('need')) {
      reply =
          "📋 **NGO Demand Board & Needs**:\n\n• **For Donors**: View items requested by NGOs under NGO Demands and tap **'🙋 I Want to Help'** to match specific items.";
    } else if (q.contains('zero') || q.contains('waste') || q.contains('recycle') || q.contains('upcycle') || q.contains('earth')) {
      reply =
          "♻️ **Zero-Waste Upcycling Routing**:\n\nItems tagged as *'Fair / Worn Out'* bypass standard feeds and route to Certified Zero-Waste Upcycling Hubs (textiles, e-waste, plastics) to earn **Earth Guardian Badges**!";
    } else if (q.contains('courier') || q.contains('porter') || q.contains('uber')) {
      reply = "🚚 **Courier Dispatch**: NGOs can dispatch Porter or Uber Connect couriers directly from the donation feed with live driver & vehicle tracking!";
    } else if (q.contains('ngo') || q.contains('directory')) {
      reply = "🏢 **Verified NGO Directory**: Explore authenticated non-profits under Explore tab. Donors can view missions, office locations, and ratings.";
    }

    // 2. High-Speed Gemini API call with tight 2.5s timeout for general queries
    if (reply.isEmpty) {
      try {
        final res = await ApiService.post('/chatbot/gemini', {'prompt': userQuery})
            .timeout(const Duration(milliseconds: 2500));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['success'] == true && data['reply'] != null && data['reply'].toString().isNotEmpty) {
            reply = data['reply'].toString().trim();
          }
        }
      } catch (_) {}
    }

    if (reply.isEmpty) {
      reply = "🤖 I am GreenDrop AI! I can guide you on donation listings, 80G tax receipts, Porter courier dispatches, 2-way passcodes, and disaster relief drives.";
    }

    if (!mounted) return;
    setState(() {
      _isThinking = false;
      _messages.add({'sender': 'bot', 'text': reply});
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.canPop(context);
    final Widget content = Column(
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/ai_chat_icon.png',
                            height: 24,
                            width: 24,
                            fit: BoxFit.cover,
                          ),
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
        if (_isThinking) const LinearProgressIndicator(color: Colors.green, minHeight: 3),

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

    if (canPop) {
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.smart_toy_rounded, size: 22),
              SizedBox(width: 8),
              Text('GreenDrop AI HelpBot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    }

    return content;
  }
}
