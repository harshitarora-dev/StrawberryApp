import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/utils/responsive.dart';
import 'package:strawberry/core/widgets/app_button.dart';
import 'about_model.dart';
import 'about_service.dart';

class EditAboutPage extends StatefulWidget {
  final AboutInfo initialInfo;

  const EditAboutPage({super.key, required this.initialInfo});

  @override
  State<EditAboutPage> createState() => _EditAboutPageState();
}

class _EditAboutPageState extends State<EditAboutPage> {
  final _aboutService = AboutService();
  final _picker = ImagePicker();

  late TextEditingController _schoolNameCtrl;
  late TextEditingController _schoolTaglineCtrl;
  late TextEditingController _aboutSchoolCtrl;
  late TextEditingController _founderNameCtrl;
  late TextEditingController _founderTitleCtrl;
  late TextEditingController _founderJourneyCtrl;
  late TextEditingController _developerCreditCtrl;
  late TextEditingController _contactEmailCtrl;
  late TextEditingController _contactPhoneCtrl;
  late TextEditingController _addressCtrl;

  String _schoolImageUrl = '';
  String _founderImageUrl = '';

  File? _newSchoolImageFile;
  File? _newFounderImageFile;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final info = widget.initialInfo;
    _schoolNameCtrl = TextEditingController(text: info.schoolName);
    _schoolTaglineCtrl = TextEditingController(text: info.schoolTagline);
    _aboutSchoolCtrl = TextEditingController(text: info.aboutSchool);
    _founderNameCtrl = TextEditingController(text: info.founderName);
    _founderTitleCtrl = TextEditingController(text: info.founderTitle);
    _founderJourneyCtrl = TextEditingController(text: info.founderJourney);
    _developerCreditCtrl = TextEditingController(text: info.developerCredit);
    _contactEmailCtrl = TextEditingController(text: info.contactEmail);
    _contactPhoneCtrl = TextEditingController(text: info.contactPhone);
    _addressCtrl = TextEditingController(text: info.address);

    _schoolImageUrl = info.schoolImageUrl;
    _founderImageUrl = info.founderImageUrl;
  }

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _schoolTaglineCtrl.dispose();
    _aboutSchoolCtrl.dispose();
    _founderNameCtrl.dispose();
    _founderTitleCtrl.dispose();
    _founderJourneyCtrl.dispose();
    _developerCreditCtrl.dispose();
    _contactEmailCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isSchoolImage}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Pick from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Take Photo with Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 90);
      if (picked != null) {
        setState(() {
          if (isSchoolImage) {
            _newSchoolImageFile = File(picked.path);
          } else {
            _newFounderImageFile = File(picked.path);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_schoolNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter School Name'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      String schoolImg = _schoolImageUrl;
      String founderImg = _founderImageUrl;

      if (_newSchoolImageFile != null) {
        schoolImg = await _aboutService.uploadImage(
          _newSchoolImageFile!,
          prefix: 'school_hero',
        );
      }

      if (_newFounderImageFile != null) {
        founderImg = await _aboutService.uploadImage(
          _newFounderImageFile!,
          prefix: 'founder_photo',
        );
      }

      final updatedInfo = AboutInfo(
        schoolName: _schoolNameCtrl.text.trim(),
        schoolTagline: _schoolTaglineCtrl.text.trim(),
        schoolImageUrl: schoolImg,
        aboutSchool: _aboutSchoolCtrl.text.trim(),
        founderName: _founderNameCtrl.text.trim(),
        founderTitle: _founderTitleCtrl.text.trim(),
        founderImageUrl: founderImg,
        founderJourney: _founderJourneyCtrl.text.trim(),
        developerCredit: _developerCreditCtrl.text.trim(),
        contactEmail: _contactEmailCtrl.text.trim(),
        contactPhone: _contactPhoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );

      await _aboutService.saveAboutInfo(updatedInfo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('About page updated successfully! ✨'),
          backgroundColor: AppColors.emerald,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save changes: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 20),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(title, style: AppTypography.h3),
        ],
      ),
    );
  }

  Widget _buildImageSelector({
    required String title,
    required String currentUrl,
    required File? newFile,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDecorations.radiusMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              ClipRRect(
                borderRadius: AppDecorations.radiusSm,
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: newFile != null
                      ? Image.file(newFile, fit: BoxFit.cover)
                      : currentUrl.isNotEmpty
                          ? Image.network(
                              currentUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _imagePlaceholder(),
                            )
                          : _imagePlaceholder(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onPick,
                      icon: const Icon(Icons.photo_camera_rounded, size: 16),
                      label: Text(newFile != null || currentUrl.isNotEmpty ? 'Change Photo' : 'Upload Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primaryDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: AppDecorations.radiusSm),
                      ),
                    ),
                    if (newFile != null || currentUrl.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                        label: const Text('Remove Photo', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.primarySoft,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.primary, size: 32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Institute & Story', style: AppTypography.h2),
        actions: [
          if (!_saving)
            TextButton(
              onPressed: _save,
              child: Text(
                'Save',
                style: AppTypography.button.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: Center(
        child: ResponsiveContentWrapper(
          maxWidth: 680,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              // Notice banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: AppDecorations.radiusMd,
                  border: Border.all(color: AppColors.amberDark.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_rounded, color: AppColors.amberDark, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Primary Admin Exclusive: Changes saved here will immediately reflect on the About page for all users.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.amberDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Section 1: School Overview
              _buildSectionHeader('School Overview & Cover', Icons.school_rounded),
              _buildImageSelector(
                title: 'School Cover Photo',
                currentUrl: _schoolImageUrl,
                newFile: _newSchoolImageFile,
                onPick: () => _pickImage(isSchoolImage: true),
                onRemove: () {
                  setState(() {
                    _newSchoolImageFile = null;
                    _schoolImageUrl = '';
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _schoolNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'School / Institute Name',
                  prefixIcon: Icon(Icons.domain_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _schoolTaglineCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tagline / Motto',
                  prefixIcon: Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _aboutSchoolCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'About School Description',
                  alignLabelWithHint: true,
                ),
              ),

              // Section 2: Founder's Journey
              _buildSectionHeader('Founder & Journey Story', Icons.history_edu_rounded),
              _buildImageSelector(
                title: 'Founder / Director Photo',
                currentUrl: _founderImageUrl,
                newFile: _newFounderImageFile,
                onPick: () => _pickImage(isSchoolImage: false),
                onRemove: () {
                  setState(() {
                    _newFounderImageFile = null;
                    _founderImageUrl = '';
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _founderNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Founder / Director Name',
                  prefixIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _founderTitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Designation / Title',
                  prefixIcon: Icon(Icons.badge_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _founderJourneyCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Founder\'s Vision & Journey Story',
                  alignLabelWithHint: true,
                ),
              ),

              // Section 3: Developer Attribution
              _buildSectionHeader('Developer Attribution', Icons.code_rounded),
              TextField(
                controller: _developerCreditCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Developer Credit & Inquiries',
                  prefixIcon: Icon(Icons.favorite_rounded, color: AppColors.primary),
                ),
              ),

              // Section 4: Contact & Location Info
              _buildSectionHeader('Contact & Campus Location', Icons.contact_support_rounded),
              TextField(
                controller: _contactEmailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Email',
                  prefixIcon: Icon(Icons.mail_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contactPhoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone / Helpline',
                  prefixIcon: Icon(Icons.phone_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Campus Address',
                  prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.primary),
                ),
              ),

              const SizedBox(height: 30),

              AppButton(
                label: _saving ? 'Saving Changes...' : 'Save & Publish Changes',
                icon: Icons.check_circle_rounded,
                loading: _saving,
                onPressed: _saving ? null : _save,
                variant: AppButtonVariant.primary,
                height: 52,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
