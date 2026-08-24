import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_service.dart';

import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';

class _Palette {
  static const primary = AppColors.primary;
  static const primaryDark = AppColors.primaryDark;
  static const primarySoft = AppColors.primarySoft;
  static const accentPeach = AppColors.primaryLight;

  static const bg = AppColors.background;
  static const surface = AppColors.surface;
  static const border = AppColors.borderSubtle;

  static const textDark = AppColors.textDark;
  static const textMuted = AppColors.textMuted;
  static const textFaint = AppColors.textFaint;

  static const success = AppColors.emerald;
  static const danger = AppColors.danger;
}

class CategoriesAdminPage extends StatefulWidget {
  final AuthService authService;
  const CategoriesAdminPage({Key? key, required this.authService}) : super(key: key);

  @override
  State<CategoriesAdminPage> createState() => _CategoriesAdminPageState();
}

class _CategoriesAdminPageState extends State<CategoriesAdminPage> {
  List<String> _categories = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final list = await widget.authService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addCategory(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    if (_categories.any((c) => c.toLowerCase() == cleanName.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Category "$cleanName" already exists', success: false),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.authService.addCategory(cleanName);
      _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Category "$cleanName" added successfully', success: true),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Failed to add category. Try again.', success: false),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteCategory(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _Palette.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: _Palette.danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Category',
                style: TextStyle(color: _Palette.textDark, fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the category "$name"?\n\nNote: Students currently assigned to this category will not be altered, but this category will no longer be available for new assignments.',
          style: const TextStyle(color: _Palette.textMuted, fontSize: 13.5, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: _Palette.textMuted),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _Palette.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await widget.authService.deleteCategory(name);
      _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Category "$name" removed successfully', success: true),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Failed to remove category. Try again.', success: false),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openAddCategoryDialog() {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _Palette.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_Palette.primary, _Palette.accentPeach],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.category_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Add New Category',
                  style: TextStyle(
                    color: _Palette.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the name of the new student category (e.g. Playgroup, LKG, UKG, Nursery, Tution).',
                  style: TextStyle(fontSize: 13, color: _Palette.textMuted, height: 1.4),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: _Palette.textDark, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    labelStyle: const TextStyle(color: _Palette.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.edit_rounded, color: _Palette.primary, size: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _Palette.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _Palette.primary, width: 1.6),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _Palette.danger),
                    ),
                    filled: true,
                    fillColor: _Palette.bg,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter category name';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: _Palette.textMuted),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final name = controller.text;
                Navigator.pop(context);
                _addCategory(name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _Palette.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  SnackBar _snack(String message, {required bool success}) {
    return SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: success ? _Palette.success : _Palette.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      appBar: AppBar(
        title: const Text('Manage Categories',
            style: TextStyle(color: _Palette.textDark, fontWeight: FontWeight.w800, fontSize: 19)),
        backgroundColor: _Palette.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _Palette.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: _Palette.border, width: 1)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddCategoryDialog,
        backgroundColor: _Palette.primary,
        elevation: 2,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator(color: _Palette.primary))
              : _categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: _Palette.textFaint.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.category_rounded, size: 46, color: _Palette.textFaint),
                          ),
                          const SizedBox(height: 18),
                          const Text('No Categories Configured',
                              style: TextStyle(fontSize: 16.5, color: _Palette.textDark, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          const Text('Create dynamic categories using the + button',
                              style: TextStyle(fontSize: 13, color: _Palette.textMuted, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCategories,
                      color: _Palette.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: _Palette.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _Palette.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.01),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: _Palette.primarySoft,
                                child: const Icon(Icons.folder_open_rounded, color: _Palette.primary, size: 20),
                              ),
                              title: Text(
                                cat,
                                style: const TextStyle(
                                  color: _Palette.textDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.5,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: _Palette.danger, size: 20),
                                onPressed: () => _deleteCategory(cat),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          if (_saving)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(color: _Palette.primary),
              ),
            ),
        ],
      ),
    );
  }
}
