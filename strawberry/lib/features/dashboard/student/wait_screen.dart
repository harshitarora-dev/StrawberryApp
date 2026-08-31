import 'package:flutter/material.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/widgets/app_button.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/auth/auth_screen.dart';
import 'package:strawberry/features/dashboard/student/home_screen.dart';
import 'package:strawberry/features/dashboard/admin/admin_dashboard.dart';

class WaitScreen extends StatefulWidget {
  /// Pass [isRejected] = true when coming from the rejection flow
  final bool isRejected;
  const WaitScreen({super.key, this.isRejected = false});

  @override
  State<WaitScreen> createState() => _WaitScreenState();
}

class _WaitScreenState extends State<WaitScreen> {
  final _authService = AuthService();
  bool _loading = false;
  late bool _isRejected;

  @override
  void initState() {
    super.initState();
    _isRejected = widget.isRejected;
  }

  Future<void> _checkStatus() async {
    setState(() => _loading = true);

    try {
      final profile = await _authService.getCurrentProfile();
      if (!mounted) return;

      if (profile != null) {
        final status = profile['status'];
        final role = profile['role'];

        if (status == 'approved') {
          if (role == 'admin') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
          return;
        }

        // Update rejection status dynamically
        if (status == 'rejected' && !_isRejected) {
          setState(() => _isRejected = true);
          return;
        }
        if (status == 'pending' && _isRejected) {
          setState(() => _isRejected = false);
        }
      }

      if (!_isRejected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your request is still pending approval from the administrator.',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.amberDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check status. Please try again.', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reRequestApproval() async {
    setState(() => _loading = true);
    try {
      final uid = _authService.currentUserId;
      if (uid == null) throw Exception('Not logged in');
      await _authService.reRequestApproval(uid);
      if (!mounted) return;
      setState(() {
        _isRejected = false;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your request has been re-submitted for approval.',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to re-submit request. Please try again.', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _isRejected ? _buildRejectedView() : _buildPendingView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: FloatingWobble(
            verticalOffset: 6,
            rotationAngle: 0.04,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.amberSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 48,
                color: AppColors.amberDark,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Pending Admin Approval',
          textAlign: TextAlign.center,
          style: AppTypography.h1.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDecorations.radiusLg,
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppDecorations.shadowSm,
          ),
          child: Text(
            'Your account registration has been submitted to the preschool administrator. You will get instant access once your admission profile is verified.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ),
        const Spacer(),
        AppButton(
          label: 'Check Status Now',
          icon: Icons.refresh_rounded,
          loading: _loading,
          onPressed: _checkStatus,
          variant: AppButtonVariant.primary,
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Log Out',
          icon: Icons.logout_rounded,
          onPressed: _logout,
          variant: AppButtonVariant.text,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRejectedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.cancel_rounded,
              size: 48,
              color: AppColors.danger,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Application Not Approved',
          textAlign: TextAlign.center,
          style: AppTypography.h1.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDecorations.radiusLg,
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppDecorations.shadowSm,
          ),
          child: Text(
            'Your registration could not be verified at this moment. You can re-submit your verification request or contact the school office.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ),
        const Spacer(),
        AppButton(
          label: 'Re-submit Application',
          icon: Icons.send_rounded,
          loading: _loading,
          onPressed: _reRequestApproval,
          variant: AppButtonVariant.primary,
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Log Out',
          icon: Icons.logout_rounded,
          onPressed: _logout,
          variant: AppButtonVariant.text,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
