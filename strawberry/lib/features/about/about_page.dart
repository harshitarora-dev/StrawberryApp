import 'package:flutter/material.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/utils/responsive.dart';
import 'package:strawberry/core/widgets/app_badge.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'about_model.dart';
import 'about_service.dart';
import 'edit_about_page.dart';

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
        gradient: AppColors.primaryGradient,
        borderRadius: AppDecorations.radiusXl,
        boxShadow: AppDecorations.primaryGlow,
      ),
      child: Stack(
        children: [
          // Background photo overlay if available
          if (_info.schoolImageUrl.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: AppDecorations.radiusXl,
                child: Opacity(
                  opacity: 0.18,
                  child: Image.network(
                    _info.schoolImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppBadge(
                            label: 'Preschool & Daycare',
                            type: AppBadgeType.primary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _info.schoolName,
                            style: AppTypography.h1.copyWith(
                              color: Colors.white,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _info.schoolTagline,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontStyle: FontStyle.italic,
                    height: 1.4,
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
      {'icon': Icons.security_rounded, 'title': 'Child-Safe Campus', 'color': AppColors.emerald},
      {'icon': Icons.palette_rounded, 'title': 'Activity-Based Learning', 'color': AppColors.violet},
      {'icon': Icons.favorite_rounded, 'title': 'Loving & Caring Staff', 'color': AppColors.primary},
      {'icon': Icons.wb_sunny_rounded, 'title': 'Hygienic Daycare', 'color': AppColors.amberDark},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: highlights.length,
      itemBuilder: (ctx, i) {
        final h = highlights[i];
        final color = h['color'] as Color;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppDecorations.radiusMd,
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppDecorations.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppDecorations.radiusSm,
                ),
                child: Icon(h['icon'] as IconData, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  h['title'] as String,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSchoolStoryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDecorations.radiusLg,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppDecorations.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_info.schoolImageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: AppDecorations.radiusMd,
              child: Image.network(
                _info.schoolImageUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              const Icon(Icons.school_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text('About Our School', style: AppTypography.h2),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _info.aboutSchool,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textBody,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFounderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDecorations.radiusLg,
        border: Border.all(color: AppColors.primarySoft),
        boxShadow: AppDecorations.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_info.founderImageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.network(
                    _info.founderImageUrl,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _founderAvatarFallback(),
                  ),
                )
              else
                _founderAvatarFallback(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_info.founderName, style: AppTypography.h2),
                    const SizedBox(height: 2),
                    Text(
                      _info.founderTitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.35),
              borderRadius: AppDecorations.radiusMd,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _info.founderJourney,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textDark,
                      height: 1.55,
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
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.person_rounded, color: AppColors.primary, size: 30),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDecorations.radiusLg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Campus & Contact', style: AppTypography.h3),
            ],
          ),
          const SizedBox(height: 12),
          if (_info.address.isNotEmpty) ...[
            _contactRow(Icons.place_outlined, _info.address),
            const SizedBox(height: 8),
          ],
          if (_info.contactPhone.isNotEmpty) ...[
            _contactRow(Icons.phone_outlined, _info.contactPhone),
            const SizedBox(height: 8),
          ],
          if (_info.contactEmail.isNotEmpty) ...[
            _contactRow(Icons.email_outlined, _info.contactEmail),
          ],
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textBody),
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.violetSoft.withValues(alpha: 0.4),
            AppColors.primarySoft.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: AppDecorations.radiusLg,
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppDecorations.radiusSm,
              boxShadow: AppDecorations.shadowSm,
            ),
            child: const Icon(Icons.code_rounded, color: AppColors.violet, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Developer',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.violetDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _info.developerCredit,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('About Strawberry', style: AppTypography.h2),
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadInfo,
              color: AppColors.primary,
              child: Center(
                child: ResponsiveContentWrapper(
                  maxWidth: 720,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    children: [
                      _buildHeroBanner(),
                      const SizedBox(height: 20),

                      _buildHighlightsPills(),
                      const SizedBox(height: 20),

                      _buildSchoolStoryCard(),
                      const SizedBox(height: 20),

                      _buildFounderCard(),
                      const SizedBox(height: 20),

                      _buildContactCard(),
                      const SizedBox(height: 20),

                      _buildDeveloperCard(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
