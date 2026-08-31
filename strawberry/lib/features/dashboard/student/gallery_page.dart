import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/utils/responsive.dart';
import 'package:strawberry/core/widgets/app_empty_state.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';
import 'package:strawberry/features/auth/auth_service.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _allImages = [];
  String _selectedCategory = 'All';
  bool _loading = true;

  static const List<({String name, String emoji, Color color})> _categoryFilters = [
    (name: 'All', emoji: '🌟', color: AppColors.primary),
    (name: 'Little Artists', emoji: '🎨', color: AppColors.sky),
    (name: 'Rhymes & Music', emoji: '🎪', color: AppColors.amber),
    (name: 'Play Zone & Fun', emoji: '🛝', color: AppColors.emerald),
    (name: 'Celebrations', emoji: '🎉', color: AppColors.primaryLight),
    (name: 'Snack & Circle Time', emoji: '🍎', color: AppColors.violet),
    (name: 'Tiny Tots Daycare', emoji: '🧸', color: AppColors.indigo),
  ];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _loading = true);
    try {
      final images = await _authService.getGalleryImages();
      if (!mounted) return;
      setState(() {
        _allImages = images;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredImages {
    if (_selectedCategory == 'All') return _allImages;
    return _allImages.where((img) {
      final cat = (img['category'] as String?) ?? 'Fun Moment';
      return cat.toLowerCase().contains(_selectedCategory.toLowerCase());
    }).toList();
  }

  int _countForCategory(String category) {
    if (category == 'All') return _allImages.length;
    return _allImages.where((img) {
      final cat = (img['category'] as String?) ?? 'Fun Moment';
      return cat.toLowerCase().contains(category.toLowerCase());
    }).length;
  }

  String _getCategoryEmoji(String? category) {
    if (category == null) return '🍓';
    final lower = category.toLowerCase();
    if (lower.contains('art') || lower.contains('craft') || lower.contains('paint') || lower.contains('artist')) return '🎨';
    if (lower.contains('rhyme') || lower.contains('music') || lower.contains('dance')) return '🎪';
    if (lower.contains('play') || lower.contains('fun') || lower.contains('zone') || lower.contains('sport')) return '🛝';
    if (lower.contains('celebrat') || lower.contains('event') || lower.contains('festival')) return '🎉';
    if (lower.contains('snack') || lower.contains('circle') || lower.contains('fruit')) return '🍎';
    if (lower.contains('daycare') || lower.contains('tot') || lower.contains('tiny') || lower.contains('playgroup')) return '🧸';
    return '🍓';
  }

  void _openLightbox(int initialIndex) {
    final images = _filteredImages;
    if (images.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (context, anim1, anim2) => _LightboxViewer(
          images: images,
          initialIndex: initialIndex,
          getCategoryEmoji: _getCategoryEmoji,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.getGridColumns(context, mobile: 2, tablet: 3, desktop: 4, largeDesktop: 5);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Preschool Moments 🎨'),
        actions: [
          if (_allImages.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppDecorations.radiusFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_rounded, size: 13, color: AppColors.primaryDark),
                  const SizedBox(width: 4),
                  Text(
                    '${_allImages.length}',
                    style: AppTypography.badge.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1024;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
            final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

            return Column(
              children: [
                // ── Category Filter Bar ─────────────────────────────────
                _buildCategoryFilterBar(),

                // ── Photo Grid / State ─────────────────────────────────
                Expanded(
                  child: _loading
                      ? const StrawberryLoader(message: 'Loading campus memories... 🎓')
                      : _filteredImages.isEmpty
                          ? AppEmptyState(
                              icon: Icons.photo_library_outlined,
                              title: 'No Photos in $_selectedCategory',
                              subtitle: 'New campus memories will appear here once uploaded by teachers.',
                            )
                          : RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: _loadImages,
                              child: GridView.builder(
                                padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 24),
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.88,
                                ),
                                itemCount: _filteredImages.length,
                                itemBuilder: (context, index) {
                                  final img = _filteredImages[index];
                                  return _buildAestheticPhotoCard(img, index);
                                },
                              ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryFilterBar() {
    return Container(
      height: 54,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _categoryFilters.length,
        itemBuilder: (context, index) {
          final filter = _categoryFilters[index];
          final isSelected = _selectedCategory == filter.name;
          final count = _countForCategory(filter.name);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: BouncyTap(
              onTap: () => setState(() => _selectedCategory = filter.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : AppDecorations.shadowSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingWobble(
                      verticalOffset: 1.5,
                      duration: const Duration(milliseconds: 2000),
                      child: Text(filter.emoji, style: const TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filter.name,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAestheticPhotoCard(Map<String, dynamic> img, int index) {
    final url = img['image_url'] as String;
    final cat = (img['category'] as String?) ?? 'Campus Life';
    final title = img['title'] as String?;
    final emoji = _getCategoryEmoji(cat);

    DateTime? date;
    if (img['created_at'] != null) {
      date = DateTime.tryParse(img['created_at'].toString());
    }
    final dateStr = date != null ? DateFormat('d MMM').format(date) : null;

    return StaggeredEntrance(
      index: index,
      slideOffset: 25,
      child: Hero(
        tag: 'gallery_photo_${img['id'] ?? url}',
        child: Material(
          color: Colors.transparent,
          child: BouncyTap(
            onTap: () => _openLightbox(index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                // Background Image with smooth loading
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppColors.surfaceAlt,
                      child: const Center(
                        child: BtnLoader(color: AppColors.primary, dotSize: 5),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surfaceAlt,
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                    ),
                  ),
                ),

                // Top right zoom indicator badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),

                // Bottom Gradient Scrim & Category Chip
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null && title.isNotEmpty) ...[
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                        ],
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(emoji, style: const TextStyle(fontSize: 10)),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        cat,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (dateStr != null)
                              Text(
                                dateStr,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}

// ---------------------------------------------------------------------------
// Modern Full-Screen Lightbox & Swipeable Viewer
// ---------------------------------------------------------------------------
class _LightboxViewer extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final int initialIndex;
  final String Function(String?) getCategoryEmoji;

  const _LightboxViewer({
    required this.images,
    required this.initialIndex,
    required this.getCategoryEmoji,
  });

  @override
  State<_LightboxViewer> createState() => _LightboxViewerState();
}

class _LightboxViewerState extends State<_LightboxViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _shareImage(String url) {
    SharePlus.instance.share(
      ShareParams(
        text: 'Check out this photo from Strawberry Preschool & Daycare! 🍓 $url',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentImg = widget.images[_currentIndex];
    final cat = (currentImg['category'] as String?) ?? 'Campus Life';
    final title = currentImg['title'] as String?;
    final emoji = widget.getCategoryEmoji(cat);

    DateTime? date;
    if (currentImg['created_at'] != null) {
      date = DateTime.tryParse(currentImg['created_at'].toString());
    }
    final dateStr = date != null ? DateFormat('EEEE, d MMMM yyyy').format(date) : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Swipeable Photo View
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemBuilder: (context, index) {
              final img = widget.images[index];
              final url = img['image_url'] as String;
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: BtnLoader(color: Colors.white),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Top Header Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                      onPressed: () => _shareImage(currentImg['image_url']),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Caption / Category Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 5),
                              Text(
                                cat,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (dateStr != null)
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    if (title != null && title.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
