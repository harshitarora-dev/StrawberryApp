import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Native Flutter Privacy Policy page for Strawberry Preschool & Daycare.
/// The top header/navbar is completely non-fixed and scrolls naturally with page content.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF0F3), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFFFE4E8), width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFFE4E8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFFD32F52)),
                      SizedBox(width: 6),
                      Text(
                        'Back',
                        style: TextStyle(
                          color: Color(0xFFD32F52),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🍓', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 6),
                    Text(
                      'STRAWBERRY APP',
                      style: TextStyle(
                        color: Color(0xFFD32F52),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Privacy & Data Policy',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Last updated: September 2026 • Strawberry Preschool & Daycare, Faridabad',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String number,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE94464).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0F3),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Color(0xFFE94464),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF1F5F9), height: 16),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBullet(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 6, color: Color(0xFFE94464)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF334155),
                  fontFamily: 'Plus Jakarta Sans',
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(IconData icon, String label, String value, [VoidCallback? onTap]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFFD32F52)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      // No fixed AppBar! Top header/navbar is placed inside the SingleChildScrollView
      // so it scrolls away naturally with the page content.
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Non-fixed header / navbar
            _buildTopHeader(context),

            // Policy Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intro
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F7),
                        borderRadius: BorderRadius.circular(16),
                        border: const Border(
                          left: BorderSide(color: Color(0xFFE94464), width: 4),
                        ),
                      ),
                      child: const Text(
                        'At Strawberry Preschool & Daycare, we are deeply committed to protecting the privacy, safety, and personal data of our young students, parents, and guardians.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0xFF881337),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Section 1
                    _buildSectionCard(
                      number: '1',
                      title: 'Information We Collect',
                      children: [
                        _buildBullet('Parent & Guardian Details', 'Name, email address, phone number, and relationship to the child during Google Sign-In and onboarding.'),
                        _buildBullet('Student Information', 'Student full name, enrolled programs/categories (Playgroup, Pre-Nursery, Nursery, Kindergarten, Daycare), and enrollment dates.'),
                        _buildBullet('Attendance Records', 'Daily check-in, presence/absence timestamps, and holiday schedules.'),
                        _buildBullet('Campus Photo Gallery', 'School event photos and classroom activities securely stored in our cloud repository.'),
                        _buildBullet('Device & Push Tokens', 'FCM device tokens for delivering real-time notices, chat messages, and attendance alerts.'),
                      ],
                    ),

                    // Section 2
                    _buildSectionCard(
                      number: '2',
                      title: 'How We Use Your Information',
                      children: [
                        _buildBullet('School Communication', 'Delivering notices, holiday announcements, circulars, and direct in-app messaging between parents and school admin.'),
                        _buildBullet('Attendance Tracking & Reporting', 'Generating student attendance heatmaps and authorized administrative Excel reports.'),
                        _buildBullet('Fee & Account Management', 'Managing student fee records, custom fee heads, and digital payment receipts.'),
                        _buildBullet('Child Safety & Verification', 'Ensuring only verified parents and school administrators have access to classroom updates.'),
                      ],
                    ),

                    // Section 3
                    _buildSectionCard(
                      number: '3',
                      title: 'Data Protection & Security',
                      children: [
                        const Text(
                          'We employ industry-grade encryption and secure PostgreSQL protocols via Supabase and Firebase Auth to protect student and parent records. Access to financial data and administration is strictly restricted to verified Primary Admins.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),

                    // Section 4
                    _buildSectionCard(
                      number: '4',
                      title: 'Third-Party Services',
                      children: [
                        _buildBullet('Firebase (Google)', 'Authentication and Cloud Messaging (FCM).'),
                        _buildBullet('Supabase', 'PostgreSQL database and media storage for gallery photos.'),
                        _buildBullet('Google Sign-In', 'Frictionless authentication without storing sensitive passwords on our servers.'),
                      ],
                    ),

                    // Section 5
                    _buildSectionCard(
                      number: '5',
                      title: 'Contact Us',
                      children: [
                        _buildContactTile(
                          Icons.location_on_rounded,
                          'Campus Address',
                          'BPTP Parklands, C-22, Sector 85, Faridabad, Haryana 121007',
                        ),
                        _buildContactTile(
                          Icons.phone_rounded,
                          'Phone Number',
                          '+91 99992 49495',
                          () => launchUrl(Uri.parse('tel:+919999249495')),
                        ),
                        _buildContactTile(
                          Icons.email_rounded,
                          'Email Address',
                          'daycarestrawberry@gmail.com',
                          () => launchUrl(Uri.parse('mailto:daycarestrawberry@gmail.com')),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '© 2026 Strawberry Preschool & Daycare • Sector 85, Faridabad',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
