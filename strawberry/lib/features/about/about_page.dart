import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/core/utils/url_navigation.dart';
import 'about_model.dart';
import 'about_service.dart';
import 'edit_about_page.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final _aboutService = AboutService();
  final _authService = AuthService();

  AboutInfo _info = AboutInfo.defaults();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    setState(() => _loading = true);
    try {
      final info = await _aboutService.getAboutInfo();
      if (!mounted) return;
      setState(() {
        _info = info;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool get _isPrimaryAdmin {
    final email = _authService.currentUserEmail;
    return AboutService.isPrimaryAdmin(email);
  }

  Future<void> _openEditor() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditAboutPage(initialInfo: _info),
      ),
    );
    if (updated == true) {
      _loadInfo();
    }
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE93B61), Color(0xFFC72847)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE93B61).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background photo overlay if available
          if (_info.schoolImageUrl.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Opacity(
                  opacity: 0.15,
                  child: _info.schoolImageUrl.startsWith('assets/')
                      ? Image.asset(
                          _info.schoolImageUrl,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          _info.schoolImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'PRESCHOOL & DAYCARE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _info.schoolName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '“${_info.schoolTagline}”',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsPills() {
    final highlights = [
      {'icon': Icons.security_rounded, 'title': 'Child-Safe Campus', 'subtitle': '24/7 Monitored & Secure', 'color': AppColors.emerald},
      {'icon': Icons.palette_rounded, 'title': 'Activity-Based', 'subtitle': 'Montessori Curriculum', 'color': AppColors.violet},
      {'icon': Icons.favorite_rounded, 'title': 'Loving Mentors', 'subtitle': 'Trained & Caring Educators', 'color': AppColors.primary},
      {'icon': Icons.wb_sunny_rounded, 'title': 'Hygienic Daycare', 'subtitle': 'Clean & Healthy Spaces', 'color': AppColors.amberDark},
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final crossAxisCount = constraints.maxWidth < 450 ? 1 : 2;
        final childAspectRatio = constraints.maxWidth < 450
            ? 3.4
            : (constraints.maxWidth < 700 ? 2.5 : 2.8);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: highlights.length,
          itemBuilder: (ctx, i) {
            final h = highlights[i];
            final color = h['color'] as Color;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(h['icon'] as IconData, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          h['subtitle'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSchoolStoryCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_info.schoolImageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _info.schoolImageUrl.startsWith('assets/')
                  ? Image.asset(
                      _info.schoolImageUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      _info.schoolImageUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
            ),
            const SizedBox(height: 18),
          ],
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'About Our School',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _info.aboutSchool,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              color: AppColors.textBody,
              fontSize: 14,
              height: 1.65,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFounderCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primarySoft.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_info.founderImageUrl.isNotEmpty)
                ClipOval(
                  child: _info.founderImageUrl.startsWith('assets/')
                      ? Image.asset(
                          _info.founderImageUrl,
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        )
                      : Image.network(
                          _info.founderImageUrl,
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, _, _) => _founderAvatarFallback(),
                        ),
                )
              else
                _founderAvatarFallback(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _info.founderName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _info.founderTitle,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _info.founderJourney,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _founderAvatarFallback() {
    return Container(
      width: 62,
      height: 62,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.person_rounded, color: AppColors.primary, size: 32),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.skySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.sky, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Campus & Contact Details',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_info.address.isNotEmpty) ...[
            _contactRow(
              Icons.place_rounded,
              _info.address,
              onTap: () async {
                final uri = Uri.parse(_info.googleMapsUrl);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
              actionLabel: 'Maps ↗',
            ),
            const SizedBox(height: 10),
          ],
          if (_info.contactPhone.isNotEmpty) ...[
            _contactRow(
              Icons.phone_rounded,
              _info.contactPhone,
              onTap: () async {
                final uri = Uri.parse('tel:${_info.contactPhone.replaceAll(' ', '')}');
                try {
                  await launchUrl(uri);
                } catch (_) {}
              },
              actionLabel: 'Call',
            ),
            const SizedBox(height: 10),
          ],
          if (_info.contactEmail.isNotEmpty) ...[
            _contactRow(
              Icons.email_rounded,
              _info.contactEmail,
              onTap: () async {
                final uri = Uri.parse('mailto:${_info.contactEmail}');
                try {
                  await launchUrl(uri);
                } catch (_) {}
              },
            ),
            const SizedBox(height: 10),
          ],
          if (!kIsWeb && _info.websiteUrl.isNotEmpty) ...[
            _contactRow(
              Icons.language_rounded,
              _info.websiteUrl,
              onTap: () async {
                final uri = Uri.parse(_info.websiteUrl);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
              actionLabel: 'Visit ↗',
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          const Text(
            'Connect & Follow Us',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (!kIsWeb && _info.websiteUrl.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _launchExternal(_info.websiteUrl),
                  icon: const Icon(Icons.language_rounded, size: 16, color: Color(0xFF0F9D58)),
                  label: const Text(
                    'Official Website',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F9D58),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0F9D58), width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: const StadiumBorder(),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: () => _launchExternal(
                  _info.googleMapsUrl.isNotEmpty
                      ? _info.googleMapsUrl
                      : 'https://maps.app.goo.gl/efvVwz7AMGXp1EC68',
                ),
                icon: SvgPicture.asset(
                  'assets/images/google_maps.svg',
                  width: 16,
                  height: 16,
                ),
                label: const Text(
                  'Google Maps',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: const StadiumBorder(),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _launchExternal(
                  _info.instagramUrl.isNotEmpty
                      ? _info.instagramUrl
                      : 'https://www.instagram.com/strawberry.preschool/',
                ),
                icon: SvgPicture.asset(
                  'assets/images/instagram.svg',
                  width: 16,
                  height: 16,
                ),
                label: const Text(
                  'Instagram',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE1306C),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE1306C), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: const StadiumBorder(),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _launchExternal(
                  _info.facebookUrl.isNotEmpty
                      ? _info.facebookUrl
                      : 'https://www.facebook.com/daycare.strawberry',
                ),
                icon: SvgPicture.asset(
                  'assets/images/facebook.svg',
                  width: 16,
                  height: 16,
                ),
                label: const Text(
                  'Facebook',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1877F2),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1877F2), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text, {VoidCallback? onTap, String? actionLabel}) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              color: onTap != null ? AppColors.primary : AppColors.textBody,
              fontWeight: onTap != null ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: row,
        ),
      );
    }
    return row;
  }

  Future<void> _launchExternal(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _buildDeveloperCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.violetSoft.withValues(alpha: 0.5),
            AppColors.primarySoft.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.code_rounded, color: AppColors.violet, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Technology & Software Credits',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.violetDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _info.developerCredit,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebsiteCard() {
    if (kIsWeb) return const SizedBox.shrink();
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(_info.websiteUrl.isNotEmpty ? _info.websiteUrl : 'https://strawberrydaycare.co.in');
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0F9D58).withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.language_rounded, color: Color(0xFF0F9D58), size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Official School Website',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'strawberrydaycare.co.in',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0F9D58),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Visit',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F9D58),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF0F9D58)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicyCard() {
    return InkWell(
      onTap: () => openPrivacyPolicy(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy & Data Policy',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Student safety, data retention & compliance',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'About Strawberry',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          if (_isPrimaryAdmin)
            IconButton(
              tooltip: 'Edit About Institute (Admin Only)',
              icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
              onPressed: _openEditor,
            ),
        ],
      ),
      body: _loading
          ? const StrawberryLoader(message: 'Loading school info... 🏫')
          : RefreshIndicator(
              onRefresh: _loadInfo,
              color: AppColors.primary,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 960;
                  final isTablet = constraints.maxWidth >= 640 && constraints.maxWidth < 960;
                  return ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 36.0 : (isTablet ? 24.0 : 16.0),
                      vertical: 20,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    children: isDesktop
                        ? [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _buildHeroBanner(),
                                      const SizedBox(height: 20),
                                      _buildHighlightsPills(),
                                      const SizedBox(height: 20),
                                      _buildContactCard(),
                                      if (!kIsWeb) ...[
                                        const SizedBox(height: 20),
                                        _buildWebsiteCard(),
                                      ],
                                      const SizedBox(height: 20),
                                      _buildPrivacyPolicyCard(),
                                      const SizedBox(height: 20),
                                      _buildDeveloperCard(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _buildSchoolStoryCard(),
                                      const SizedBox(height: 20),
                                      _buildFounderCard(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ]
                        : [
                            _buildHeroBanner(),
                            const SizedBox(height: 18),
                            _buildHighlightsPills(),
                            const SizedBox(height: 18),
                            _buildSchoolStoryCard(),
                            const SizedBox(height: 18),
                            _buildFounderCard(),
                            const SizedBox(height: 18),
                            _buildContactCard(),
                            if (!kIsWeb) ...[
                              const SizedBox(height: 18),
                              _buildWebsiteCard(),
                            ],
                            const SizedBox(height: 18),
                            _buildPrivacyPolicyCard(),
                            const SizedBox(height: 18),
                            _buildDeveloperCard(),
                            const SizedBox(height: 30),
                          ],
                  );
                },
              ),
            ),
    );
  }
}
