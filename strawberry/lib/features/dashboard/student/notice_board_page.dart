import 'package:flutter/material.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
          final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
          final columns = isDesktop ? 2 : 1;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 12,
            ),
            child: Column(
              children: [
                _buildCategoryFilterRow(),
                const SizedBox(height: 10),
                Expanded(
                  child: _loading
                      ? const StrawberryLoader(message: 'Fetching notices from school... 📢')
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
                          child: GridView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 180,
                            ),
                            itemCount: filteredNotices.length,
                            itemBuilder: (context, index) {
                              final n = filteredNotices[index];
                              return _buildNoticeCard(n, index);
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
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
      height: 52,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index]['name']!;
          final emoji = categories[index]['emoji']!;
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              borderRadius: AppDecorations.radiusFull,
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
                  borderRadius: AppDecorations.radiusFull,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textBody,
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoticeCard(Map<String, dynamic> n, int index) {
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppDecorations.radiusLg,
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppDecorations.shadowSm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTypography.h3.copyWith(fontSize: 15.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textBody,
                  height: 1.4,
                  fontSize: 13,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}