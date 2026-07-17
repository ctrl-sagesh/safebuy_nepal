import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// "Must Know" bottom sheet explaining platform integrity measures.
/// Addresses professor's concerns about fake reviews and cold-start problem.
/// Fully bilingual (EN/NE).
class MustKnowSheet extends StatelessWidget {
  const MustKnowSheet({super.key, this.lang = 'en'});
  final String lang;

  static void show(BuildContext context, {String lang = 'en'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MustKnowSheet(lang: lang),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNe = lang == 'ne';
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A1628),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF42A5F5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isNe
                          ? 'जान्नैपर्ने कुराहरू'
                          : 'Must Know Information',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            // Content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Section 1: Anti-Bot Protection
                  _sectionHeader(
                    icon: Icons.security_rounded,
                    color: const Color(0xFFD32F2F),
                    title: isNe
                        ? 'नक्कली समीक्षा कसरी रोकिन्छ?'
                        : 'How do we prevent fake reviews?',
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  const SizedBox(height: 12),
                  _infoCard(
                    isNe
                        ? 'हरेक समीक्षा गनिनु अघि ६ वटा जाँचबाट जान्छ:'
                        : 'Every review passes six checks before it counts:',
                  ),
                  const SizedBox(height: 8),
                  _checkItem(
                    isNe
                        ? 'खाता उमेर जाँच: नयाँ खाताहरूले ७ दिन पर्खनुपर्छ'
                        : 'Account age check: New accounts must wait 7 days',
                    Icons.timer_outlined,
                  ),
                  _checkItem(
                    isNe
                        ? 'दर सीमा: प्रति दिन अधिकतम ३ समीक्षा'
                        : 'Rate limiting: Maximum 3 reviews per day',
                    Icons.speed_outlined,
                  ),
                  _checkItem(
                    isNe
                        ? 'डुप्लिकेट पत्ता लगाउने: प्रति विक्रेता एक समीक्षा मात्र'
                        : 'Duplicate detection: Only one review per seller',
                    Icons.content_copy_outlined,
                  ),
                  _checkItem(
                    isNe
                        ? 'समीक्षा कूलडाउन: समीक्षाहरू बीच १ घण्टा अन्तर'
                        : 'Review cooldown: 1 hour gap between reviews',
                    Icons.hourglass_bottom_outlined,
                  ),
                  _checkItem(
                    isNe
                        ? 'पाठ समानता विश्लेषण: कपी-पेस्ट समीक्षाहरू पत्ता लगाइन्छ'
                        : 'Text similarity analysis: Copy-paste reviews are detected',
                    Icons.text_snippet_outlined,
                  ),
                  _checkItem(
                    isNe
                        ? 'प्रमाणिकता स्कोरिङ: हरेक समीक्षालाई भार दिइन्छ'
                        : 'Authenticity scoring: Each review gets a weight (0.0 to 1.0)',
                    Icons.analytics_outlined,
                  ),
                  const SizedBox(height: 24),

                  // Section 2: Why Use SafeBuy
                  _sectionHeader(
                    icon: Icons.people_outline_rounded,
                    color: const Color(0xFF4CAF50),
                    title: isNe
                        ? 'कसैले प्रयोग नगर्दा किन प्रयोग गर्ने?'
                        : 'Why use it when nobody uses it yet?',
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.1),
                  const SizedBox(height: 12),
                  _strategyCard(
                    icon: Icons.storage_rounded,
                    color: const Color(0xFF2196F3),
                    title: isNe ? 'पूर्व-सिड गरिएको डाटाबेस' : 'Pre-seeded database',
                    body: isNe
                        ? 'एपले पहिलो लन्चमा ५ यथार्थवादी विक्रेता प्रोफाइलहरू (विश्वसनीय, अप्रमाणित, उच्च जोखिम) रिपोर्ट र समीक्षासहित स्वचालित रूपमा भर्छ।'
                        : 'The app auto-populates with 5 realistic seller profiles (trusted, unverified, high-risk) with reports and reviews on first launch.',
                  ),
                  _strategyCard(
                    icon: Icons.support_agent_rounded,
                    color: const Color(0xFFFF9800),
                    title: isNe ? 'नेटवर्क अघि नै मूल्य' : 'Value before network effect',
                    body: isNe
                        ? 'शून्य प्रयोगकर्तामा पनि: सुरक्षा सहायक, घोटाला अलर्ट, सुरक्षा सुझावहरू, र शैक्षिक सामग्रीले काम गर्छ।'
                        : 'Even with zero users: the safety assistant, scam alerts feed, safety tips, and educational content all work from day one.',
                  ),
                  _strategyCard(
                    icon: Icons.storefront_rounded,
                    color: const Color(0xFF9C27B0),
                    title: isNe ? 'विक्रेता स्व-दर्ता' : 'Seller self-registration',
                    body: isNe
                        ? 'वैध व्यवसायहरूले SafeBuy प्रमाणित ब्याज देखाएर प्रतिस्पर्धात्मक फाइदा पाउँछन्।'
                        : 'Legitimate businesses gain competitive advantage by showing their SafeBuy verified badge to potential customers.',
                  ),
                  _strategyCard(
                    icon: Icons.flag_rounded,
                    color: const Color(0xFFF44336),
                    title: isNe ? 'घोटाला पीडित अधिग्रहण' : 'Scam victim acquisition',
                    body: isNe
                        ? 'घोटालाको अनुभव पछि, प्रयोगकर्ताहरू रिपोर्ट गर्न अत्यधिक उत्प्रेरित हुन्छन्। हरेक रिपोर्टले भविष्यका खरिदकर्ताहरूको लागि मूल्य सिर्जना गर्छ।'
                        : 'After being scammed, users are highly motivated to report. Each report creates value for future buyers and grows the platform organically.',
                  ),
                  const SizedBox(height: 24),

                  // Section 3: Trust Score
                  _sectionHeader(
                    icon: Icons.calculate_outlined,
                    color: const Color(0xFFFF9800),
                    title: isNe
                        ? 'विश्वास स्कोर कसरी गणना गरिन्छ?'
                        : 'How is the trust score calculated?',
                  ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideX(begin: -0.1),
                  const SizedBox(height: 12),
                  _factorRow(isNe ? 'रिपोर्ट गम्भीरता' : 'Report Severity', '40%',
                      const Color(0xFFF44336)),
                  _factorRow(isNe ? 'प्रमाणीकरण स्थिति' : 'Verification Status',
                      '25%', const Color(0xFF2196F3)),
                  _factorRow(isNe ? 'समीक्षा प्रमाणिकता' : 'Review Authenticity',
                      '20%', const Color(0xFF4CAF50)),
                  _factorRow(isNe ? 'विवाद समाधान' : 'Dispute Resolution', '10%',
                      const Color(0xFFFF9800)),
                  _factorRow(
                      isNe ? 'खाता उमेर' : 'Account Age', '5%', const Color(0xFF9C27B0)),
                  const SizedBox(height: 16),
                  // Verdict bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _verdictChip(
                            '0-49', isNe ? 'उच्च जोखिम' : 'High Risk', const Color(0xFFF44336)),
                        const SizedBox(width: 8),
                        _verdictChip(
                            '50-79', isNe ? 'अप्रमाणित' : 'Unverified', const Color(0xFFFF9800)),
                        const SizedBox(width: 8),
                        _verdictChip(
                            '80-100', isNe ? 'विश्वसनीय' : 'Trusted', const Color(0xFF4CAF50)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF90CAF9),
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _checkItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFB0BEC5),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _strategyCard({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF90CAF9),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _factorRow(String label, String weight, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              weight,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verdictChip(String range, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              range,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
