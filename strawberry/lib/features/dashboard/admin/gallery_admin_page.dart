import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:strawberry/features/auth/auth_service.dart';

import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/utils/responsive.dart';
import 'package:strawberry/core/widgets/app_empty_state.dart';

class GalleryAdminPage extends StatefulWidget {
  final AuthService authService;
  const GalleryAdminPage({super.key, required this.authService});

  @override
  State<GalleryAdminPage> createState() => _GalleryAdminPageState();
}

class _GalleryAdminPageState extends State<GalleryAdminPage> {
  List<Map<String, dynamic>> _images = [];
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
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    setState(() => _loading = true);
    final images = await widget.authService.getGalleryImages();
    if (!mounted) return;
    setState(() {
      _images = images;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredImages {
    if (_selectedCategory == 'All') return _images;
    return _images.where((img) {
      final cat = (img['category'] as String?) ?? 'Fun Moment';
      return cat.toLowerCase().contains(_selectedCategory.toLowerCase());
    }).toList();
  }

  int _countForCategory(String category) {
    if (category == 'All') return _images.length;
    return _images.where((img) {
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

  Future<void> _openUploadModal() async {
    String selectedCat = 'Little Artists';
    final titleController = TextEditingController();
    List<XFile> pickedFiles = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Upload Campus Photos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category Selector
                  const Text(
                    'Select Album / Category',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categoryFilters.where((c) => c.name != 'All').map((cat) {
                      final isSelected = selectedCat == cat.name;
                      return ChoiceChip(
                        showCheckmark: false,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat.emoji, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(cat.name),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceAlt,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() => selectedCat = cat.name);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Title / Caption Input
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Event Title / Caption (Optional)',
                      hintText: 'e.g. Clay Modeling Workshop, Annual Sports',
                      prefixIcon: const Icon(Icons.title_rounded, size: 18, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Image Selection area
                  if (pickedFiles.isEmpty)
                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final files = await picker.pickMultiImage();
                        if (files.isNotEmpty) {
                          setSheetState(() => pickedFiles = files);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppColors.primarySoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Tap to pick photos from device',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Supports JPG, PNG (Auto-compressed)',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${pickedFiles.length} photos selected',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.emerald),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                              label: const Text('Add More'),
                              onPressed: () async {
                                final picker = ImagePicker();
                                final files = await picker.pickMultiImage();
                                if (files.isNotEmpty) {
                                  setSheetState(() => pickedFiles.addAll(files));
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: pickedFiles.length,
                            itemBuilder: (ctx, i) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: AppColors.surfaceAlt,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: FutureBuilder<Uint8List>(
                                      future: pickedFiles[i].readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                            width: 70,
                                            height: 70,
                                          );
                                        }
                                        return const Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () => setSheetState(() => pickedFiles.removeAt(i)),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Upload submit button
                  ElevatedButton(
                    onPressed: pickedFiles.isEmpty
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await _processUpload(
                              pickedFiles,
                              category: selectedCat,
                              title: titleController.text.trim(),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Upload ${pickedFiles.length} Photos to $selectedCat',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _processUpload(List<dynamic> files, {required String category, String? title}) async {
    setState(() => _loading = true);
    try {
      await widget.authService.uploadGalleryImages(
        files,
        category: category,
        title: title,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('${files.length} images added to $category!', success: true),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Failed to upload images: $e', success: false),
      );
    } finally {
      if (mounted) {
        await _loadGallery();
      }
    }
  }

  Future<void> _deleteImage(Map<String, dynamic> img) async {
    final id = img['id'] as int;
    final url = img['image_url'] as String;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Photo',
              style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this photo from the campus gallery?',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13.5, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      try {
        await widget.authService.deleteGalleryImage(id, url);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Image deleted successfully', success: true),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Failed to delete image: $e', success: false),
        );
      } finally {
        if (mounted) {
          await _loadGallery();
        }
      }
    }
  }

  SnackBar _snack(String message, {required bool success}) {
    return SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: success ? AppColors.emerald : AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.getGridColumns(context, mobile: 2, tablet: 3, desktop: 4, largeDesktop: 5);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Gallery Management',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 19),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
              child: const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 18),
            ),
            onPressed: _loading ? null : _openUploadModal,
            tooltip: 'Upload Photos',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _openUploadModal,
        backgroundColor: AppColors.primary,
        elevation: 3,
        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        label: const Text(
          'Upload Photos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1024;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
            final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  children: [
                    // ── Category Filter Bar ─────────────────────────────────
                    _buildCategoryFilterBar(),

                    // ── Photo Grid / State ─────────────────────────────────
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            )
                          : _filteredImages.isEmpty
                              ? AppEmptyState(
                                  icon: Icons.photo_library_outlined,
                                  title: 'No Photos in $_selectedCategory',
                                  subtitle: 'Tap "Upload Photos" to add campus memories to this album.',
                                )
                              : RefreshIndicator(
                                  color: AppColors.primary,
                                  onRefresh: _loadGallery,
                                  child: GridView.builder(
                                    padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 90),
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
                                      return _buildAdminPhotoCard(img);
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
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
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = filter.name),
              borderRadius: BorderRadius.circular(20),
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
                    Text(filter.emoji, style: const TextStyle(fontSize: 13)),
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

  Widget _buildAdminPhotoCard(Map<String, dynamic> img) {
    final url = img['image_url'] as String;
    final cat = (img['category'] as String?) ?? 'Campus Life';
    final title = img['title'] as String?;
    final emoji = _getCategoryEmoji(cat);

    DateTime? date;
    if (img['created_at'] != null) {
      date = DateTime.tryParse(img['created_at'].toString());
    }
    final dateStr = date != null ? DateFormat('d MMM yyyy').format(date) : null;

    return Container(
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
          // Photo
          Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: AppColors.surfaceAlt,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
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

          // Delete Button (top right)
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: () => _deleteImage(img),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),

          // Bottom Scrim & Meta Info
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
                            fontSize: 10,
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
    );
  }
}