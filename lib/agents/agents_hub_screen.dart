import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/language_provider.dart';
import 'safeguard/safeguard_chat_screen.dart';

/// Agents Hub showing all 4 AI agents with their status and capabilities.
class AgentsHubScreen extends ConsumerWidget {
  const AgentsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isNe = lang == 'ne';

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F3C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Color(0xFF42A5F5), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              isNe ? 'SafeGuard AI System' : 'SafeGuard AI System',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subtitle
          Text(
            isNe
                ? '४ बुद्धिमान agent हरू Nepal का खरिदकर्ताहरूलाई सुरक्षित राख्दै'
                : '4 intelligent agents protecting Nepal\'s buyers',
            style: const TextStyle(
              color: Color(0xFF64B5F6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // 2x2 grid
          Row(
            children: [
              Expanded(
                child: _AgentCard(
                  icon: Icons.shield_rounded,
                  iconColor: const Color(0xFF42A5F5),
                  bgColor: const Color(0xFF1565C0),
                  name: 'SafeGuard AI',
                  status: isNe ? 'अनलाइन' : 'Online',
                  statusColor: const Color(0xFF4CAF50),
                  description: isNe
                      ? 'Seller, ठगी, र कानूनी अधिकारबारे सोध्नुहोस्'
                      : 'Ask me about sellers, scams, and your legal rights',
                  capabilities: isNe
                      ? ['Seller खोज', 'ठगी मार्गदर्शन', 'ETA जानकारी', 'द्विभाषी']
                      : ['Seller lookup', 'Fraud guidance', 'ETA info', 'Bilingual'],
                  buttonLabel: isNe ? 'Chat गर्नुस्' : 'Chat Now',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SafeguardChatScreen()),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AgentCard(
                  icon: Icons.radar_rounded,
                  iconColor: const Color(0xFFFF9800),
                  bgColor: const Color(0xFFE65100),
                  name: 'Fraud Detector',
                  status: isNe ? 'सक्रिय' : 'Active',
                  statusColor: const Color(0xFF2196F3),
                  description: isNe
                      ? 'रिपोर्टहरू विश्लेषण गरी community लाई alert गर्छ'
                      : 'Analyzes reports for suspicious patterns automatically',
                  capabilities: isNe
                      ? ['Pattern पत्ता', 'Auto alert', 'Score cap', 'Admin notify']
                      : ['Pattern detect', 'Auto alerts', 'Score cap', 'Admin notify'],
                  isAutomatic: true,
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AgentCard(
                  icon: Icons.school_rounded,
                  iconColor: const Color(0xFF66BB6A),
                  bgColor: const Color(0xFF2E7D32),
                  name: 'Seller Coach',
                  status: isNe ? 'तयार' : 'Ready',
                  statusColor: const Color(0xFF66BB6A),
                  description: isNe
                      ? 'Trust score बढाउन व्यक्तिगत मार्गदर्शन'
                      : 'Personalized guidance to improve your trust score',
                  capabilities: isNe
                      ? ['Coaching cards', 'Milestone track', 'Score tips']
                      : ['Coaching cards', 'Milestone track', 'Score tips'],
                  buttonLabel: isNe ? 'Coaching हेर्नुस्' : 'View Coaching',
                  onTap: () => Navigator.pushNamed(context, '/home'),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AgentCard(
                  icon: Icons.document_scanner_rounded,
                  iconColor: const Color(0xFFAB47BC),
                  bgColor: const Color(0xFF6A1B9A),
                  name: 'Evidence Reviewer',
                  status: isNe ? 'Standby' : 'Standby',
                  statusColor: const Color(0xFF78909C),
                  description: isNe
                      ? 'Screenshot विश्लेषण गरी रिपोर्ट auto-fill गर्छ'
                      : 'Analyzes evidence screenshots and helps auto-fill reports',
                  capabilities: isNe
                      ? ['Image जाँच', 'Smart prompts', 'Quality score']
                      : ['Image analysis', 'Smart prompts', 'Quality score'],
                  buttonLabel: isNe ? 'रिपोर्ट गर्नुस्' : 'File a Report',
                  onTap: () => Navigator.pushNamed(context, '/report'),
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // How our agents work section
          _HowItWorksSection(isNe: isNe)
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms),
        ],
      ),
    );
  }
}

// ── Agent Card ─────────────────────────────────────────────────────

class _AgentCard extends StatelessWidget {
  const _AgentCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.name,
    required this.status,
    required this.statusColor,
    required this.description,
    required this.capabilities,
    this.buttonLabel,
    this.onTap,
    this.isAutomatic = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String name;
  final String status;
  final Color statusColor;
  final String description;
  final List<String> capabilities;
  final String? buttonLabel;
  final VoidCallback? onTap;
  final bool isAutomatic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const Spacer(),
              // Status dot
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF90A4AE),
              fontSize: 11,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Capabilities
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: capabilities.map((c) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  c,
                  style: const TextStyle(
                    color: Color(0xFF78909C),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Button or automatic label
          if (isAutomatic)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Runs automatically',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF546E7A),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else if (buttonLabel != null)
            SizedBox(
              width: double.infinity,
              child: Material(
                color: bgColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      buttonLabel!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── How It Works Section ───────────────────────────────────────────

class _HowItWorksSection extends StatefulWidget {
  const _HowItWorksSection({required this.isNe});
  final bool isNe;

  @override
  State<_HowItWorksSection> createState() => _HowItWorksSectionState();
}

class _HowItWorksSectionState extends State<_HowItWorksSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F2035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF42A5F5), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.isNe
                          ? 'हाम्रा agent हरू कसरी काम गर्छन्'
                          : 'How our agents work',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  _infoPoint(
                    widget.isNe
                        ? 'Rule-based AI: सबै agent हरूले keyword matching र decision tree प्रयोग गर्छन्। कुनै बाह्य AI API कल छैन।'
                        : 'Rule-based AI: All agents use keyword matching and decision trees. No external AI API calls.',
                  ),
                  _infoPoint(
                    widget.isNe
                        ? 'Offline-capable: Intent classification र coaching rules तपाईंको device मा चल्छ।'
                        : 'Offline-capable: Intent classification and coaching rules run on your device.',
                  ),
                  _infoPoint(
                    widget.isNe
                        ? 'Data सुरक्षा: कुनै data बाह्य AI service मा पठाइँदैन। सबै processing हाम्रो secure database भित्र हुन्छ।'
                        : 'Data security: No data is sent to external AI services. All processing happens within our secure database.',
                  ),
                  _infoPoint(
                    widget.isNe
                        ? 'शैक्षिक: Ethical Hacking and Cybersecurity BSc thesis को लागि निर्मित।'
                        : 'Academic: Built for BSc Ethical Hacking and Cybersecurity thesis.',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.check_circle_outline,
                color: Color(0xFF4CAF50), size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF90A4AE),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
