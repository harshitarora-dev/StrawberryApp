import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_service.dart';

import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';

// ── Design tokens (unified with AppTheme) ──────────────
class _P {
  static const primary = AppColors.primary;
  static const accentPeach = AppColors.primaryLight;
  static const amber = AppColors.amber;
  static const danger = AppColors.danger;

  static const bg = AppColors.background;
  static const surface = AppColors.surface;
  static const border = AppColors.borderSubtle;

  static const textDark = AppColors.textDark;
  static const textMuted = AppColors.textMuted;
  static const textFaint = AppColors.textFaint;
}

/// A fully self-contained page for managing the allowed-admins list.
/// It fetches its own data, so it always stays up to date regardless
/// of the parent's widget-tree lifecycle.
class ManageAdminsPage extends StatefulWidget {
  final AuthService authService;

  const ManageAdminsPage({super.key, required this.authService});

  @override
  State<ManageAdminsPage> createState() => _ManageAdminsPageState();
}

class _ManageAdminsPageState extends State<ManageAdminsPage> {
  List<String> _admins = [];
  bool _loading = true;

  static const _primaryEmail = 'dev.harshitcreations@gmail.com';

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _loading = true);
    try {
      final list = await widget.authService.getAllowedAdmins();
      if (!mounted) return;
      setState(() {
        _admins = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ── Remove ────────────────────────────────────────────────────────────
  Future<void> _removeAdmin(String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _P.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _P.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: _P.danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Remove Co-Admin',
                  style: TextStyle(
                      color: _P.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove co-admin "$email"?\n\nThey will lose access to all admin panel features.',
          style: const TextStyle(
              color: _P.textMuted, fontSize: 13.5, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: _P.textMuted),
            child: const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _P.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Remove',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.authService.removeAdmin(email);
      _showSnack('Removed co-admin $email', success: true);
      _loadAdmins(); // refresh this page's own list
    } catch (e) {
      _showSnack('Failed to remove admin: ${e.toString()}', success: false);
    }
  }

  // ── Add ───────────────────────────────────────────────────────────────
  void _openAddDialog() {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _P.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_P.primary, _P.accentPeach]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Add Allowed Admin',
                  style: TextStyle(
                      color: _P.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
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
                'Enter the email address that will be granted administrator access upon registration.',
                style: TextStyle(
                    fontSize: 13, color: _P.textMuted, height: 1.4),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                    color: _P.textDark, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle:
                      const TextStyle(color: _P.textMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.email_rounded,
                      color: _P.primary, size: 20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _P.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: _P.primary, width: 1.6),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _P.danger),
                  ),
                  filled: true,
                  fillColor: _P.bg,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter an email address';
                  }
                  final re = RegExp(
                      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
                  if (!re.hasMatch(v.trim())) {
                    return 'Enter a valid email address';
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
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: _P.textMuted),
            child: const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final email = emailCtrl.text.trim();
              try {
                await widget.authService.addAdmin(email);
                if (!ctx.mounted) return;
                Navigator.pop(ctx); // close dialog
                _showSnack('Granted Admin rights to $email', success: true);
                _loadAdmins(); // ← refresh this page's own list immediately
              } catch (_) {
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _showSnack(
                    'Failed to add admin. Please check permission.',
                    success: false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _P.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Add Admin',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  void _showSnack(String msg, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13.5)),
            ),
          ],
        ),
        backgroundColor: success ? const Color(0xFF22B07D) : _P.danger,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isPrimaryAdmin =
        widget.authService.currentUserEmail == _primaryEmail;

    return Scaffold(
      backgroundColor: _P.bg,
      appBar: AppBar(
        title: const Text(
          'Manage Admins',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _P.textDark,
            letterSpacing: 0.1,
          ),
        ),
        backgroundColor: _P.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _P.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape:
            const Border(bottom: BorderSide(color: _P.border, width: 1)),
      ),
      floatingActionButton: isPrimaryAdmin
          ? FloatingActionButton(
              onPressed: _openAddDialog,
              backgroundColor: _P.primary,
              elevation: 2,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: _loading
          ? const StrawberryLoader(message: 'Loading admin team... 👨‍💼')
          : RefreshIndicator(
              onRefresh: _loadAdmins,
              color: _P.primary,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 960;
                  final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 960;
                  final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
                  final columns = constraints.maxWidth >= 1200 ? 3 : (constraints.maxWidth >= 600 ? 2 : 1);

                  if (_admins.isEmpty) {
                    return ListView(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 90),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.admin_panel_settings_rounded,
                                  size: 52, color: _P.textFaint),
                              SizedBox(height: 12),
                              Text('No admins found',
                                  style: TextStyle(
                                      color: _P.textMuted,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return columns > 1
                      ? GridView.builder(
                          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 90),
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 82,
                          ),
                          itemCount: _admins.length,
                          itemBuilder: (context, index) {
                            final email = _admins[index];
                            final isPrimary = email == _primaryEmail;
                            return _buildAdminCard(email, isPrimary, isPrimaryAdmin);
                          },
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 90),
                          itemCount: _admins.length,
                          itemBuilder: (context, index) {
                            final email = _admins[index];
                            final isPrimary = email == _primaryEmail;
                            return _buildAdminCard(email, isPrimary, isPrimaryAdmin);
                          },
                        );
                },
              ),
            ),
    );
  }

  Widget _buildAdminCard(String email, bool isPrimary, bool isPrimaryAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _P.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isPrimary
                  ? _P.amber.withValues(alpha: 0.15)
                  : _P.bg,
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: isPrimary ? _P.amber : _P.textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(email,
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _P.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    isPrimary
                        ? 'Primary Administrator'
                        : 'Co-Administrator',
                    style: TextStyle(
                      color: isPrimary ? _P.amber : _P.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isPrimary)
              const Icon(Icons.verified_rounded, color: _P.amber, size: 20),
            if (!isPrimary && isPrimaryAdmin)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: _P.danger, size: 20),
                onPressed: () => _removeAdmin(email),
              ),
          ],
        ),
      ),
    );
  }
}
