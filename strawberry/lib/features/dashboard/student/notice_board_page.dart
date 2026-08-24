import 'package:flutter/material.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/utils/responsive.dart';
import 'package:strawberry/core/widgets/app_badge.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoticeBoardPage extends StatefulWidget {
  const NoticeBoardPage({super.key});

  @override
  State<NoticeBoardPage> createState() => _NoticeBoardPageState();
}

class _NoticeBoardPageState extends State<NoticeBoardPage> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _notices = [];
  bool _loading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() => _loading = true);
    final uid = _authService.currentUserId ?? '';
    try {
      final profile = await _authService.getCurrentProfile();
      final studentType = profile?['student_type'] as String?;
      final list = await _authService.getNoticesForStudent(uid, studentType);

      // Save last read timestamp to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_viewed_notices_time_$uid', DateTime.now().toIso8601String());

      if (!mounted) return;
      setState(() {
        _notices = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  AppBadgeType _getCategoryBadgeType(String category) {
    switch (category) {
      case 'Fees':
        return AppBadgeType.warning;
      case 'Holiday':
        return AppBadgeType.info;
      case 'Event':
        return AppBadgeType.success;
      case 'Emergency':
        return AppBadgeType.danger;
      default:
        return AppBadgeType.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotices = _selectedCategory == 'All'
        ? _notices
        : _notices
              .where((n) => (n['category'] ?? 'General') == _selectedCategory)
              .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notice Board', style: AppTypography.h2),
      ),
      body: Center(
        child: ResponsiveContentWrapper(
          maxWidth: 780,
          child: Column(
            children: [
              _buildCategoryFilterRow(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : filteredNotices.isEmpty
                    ? Center(
                        child: Text(
                          'No notices available in this category',
                          style: AppTypography.bodySmall,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotices,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: filteredNotices.length,
                          itemBuilder: (context, index) {
                            final n = filteredNotices[index];
                            final title = n['title'] ?? '';
                            final body = n['body'] ?? '';
                            final category = n['category'] ?? 'General';
                            final created = (n['last_sent_at'] ?? n['created_at']) != null
                                ? (n['last_sent_at'] ?? n['created_at']).toString().split('T').first
                                : '';

                            return StaggeredEntrance(
                              index: index,
                              slideOffset: 20,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: AppDecorations.radiusLg,
                                  border: Border.all(color: AppColors.borderSubtle),
                                  boxShadow: AppDecorations.shadowSm,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          AppBadge(
                                            label: category,
                                            type: _getCategoryBadgeType(category),
                                          ),
                                          Text(
                                            created,
                                            style: AppTypography.caption,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        title,
                                        style: AppTypography.h3.copyWith(fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        body,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.textBody,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterRow() {
    final categories = [
      {'name': 'All', 'emoji': '🍓'},
      {'name': 'General', 'emoji': '📌'},
      {'name': 'Fees', 'emoji': '💰'},
      {'name': 'Holiday', 'emoji': '🏖️'},
      {'name': 'Event', 'emoji': '🎪'},
    ];
    return Container(
      height: 58,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index]['name']!;
          final emoji = categories[index]['emoji']!;
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: BouncyTap(
              onTap: () => setState(() => _selectedCategory = cat),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingWobble(
                      verticalOffset: 1.5,
                      duration: const Duration(milliseconds: 2000),
                      child: Text(emoji, style: const TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(width: 4),
                    Text(cat),
                  ],
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceAlt,
                labelStyle: AppTypography.button.copyWith(
                  color: isSelected ? Colors.white : AppColors.textBody,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppDecorations.radiusFull,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedCategory = cat);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}