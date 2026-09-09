import 'package:flutter/material.dart';
import 'fee_service.dart';

class FeeHeadField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final double fontSize;
  final double borderRadius;
  final Color? borderColor;
  final Color? fillColor;
  final Color? textColor;
  final Color? primaryColor;
  final List<String>? suggestions;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSelected;
  final EdgeInsetsGeometry? contentPadding;

  const FeeHeadField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.fontSize = 13,
    this.borderRadius = 10,
    this.borderColor,
    this.fillColor,
    this.textColor,
    this.primaryColor,
    this.suggestions,
    this.validator,
    this.onSelected,
    this.contentPadding,
  });

  @override
  State<FeeHeadField> createState() => _FeeHeadFieldState();
}

class _FeeHeadFieldState extends State<FeeHeadField> {
  List<String> _items = List.from(FeeService.defaultFeeTitles);

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    if (widget.suggestions != null && widget.suggestions!.isNotEmpty) {
      if (mounted) setState(() => _items = widget.suggestions!);
      return;
    }
    final list = await FeeService().getFeeHeadSuggestions();
    if (mounted) {
      setState(() {
        _items = list;
      });
    }
  }

  static IconData _getIconForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('admission') || lower.contains('registration')) {
      return Icons.school_rounded;
    } else if (lower.contains('annual') || lower.contains('session')) {
      return Icons.calendar_month_rounded;
    } else if (lower.contains('curriculum') || lower.contains('tuition') || lower.contains('academic')) {
      return Icons.auto_stories_rounded;
    } else if (lower.contains('uniform') || lower.contains('dress') || lower.contains('cloth')) {
      return Icons.checkroom_rounded;
    } else if (lower.contains('book') || lower.contains('stationery') || lower.contains('notebook')) {
      return Icons.menu_book_rounded;
    } else if (lower.contains('picnic') || lower.contains('tour') || lower.contains('trip') || lower.contains('excursion')) {
      return Icons.beach_access_rounded;
    } else if (lower.contains('transport') || lower.contains('bus') || lower.contains('van')) {
      return Icons.directions_bus_rounded;
    } else if (lower.contains('exam') || lower.contains('test') || lower.contains('assessment')) {
      return Icons.edit_note_rounded;
    } else if (lower.contains('sport') || lower.contains('activity') || lower.contains('game')) {
      return Icons.sports_soccer_rounded;
    } else if (lower.contains('lab') || lower.contains('computer') || lower.contains('science')) {
      return Icons.biotech_rounded;
    } else if (lower.contains('id') || lower.contains('card') || lower.contains('badge')) {
      return Icons.badge_rounded;
    } else if (lower.contains('late') || lower.contains('penalty') || lower.contains('fine')) {
      return Icons.alarm_rounded;
    } else if (lower.contains('develop') || lower.contains('building') || lower.contains('maintenance')) {
      return Icons.domain_rounded;
    }
    return Icons.label_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final effectivePrimary = widget.primaryColor ?? const Color(0xFFE11D48);
    final effectiveText = widget.textColor ?? const Color(0xFF1E293B);
    final effectiveBorder = widget.borderColor ?? const Color(0xFFE2E8F0);

    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      style: TextStyle(
        fontSize: widget.fontSize,
        color: effectiveText,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        isDense: true,
        filled: widget.fillColor != null,
        fillColor: widget.fillColor,
        contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(color: effectiveBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(color: effectiveBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(color: effectivePrimary, width: 1.5),
        ),
        suffixIcon: PopupMenuButton<String>(
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            size: 24,
            color: effectivePrimary,
          ),
          tooltip: 'Select Standard or Past Fee Head',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(maxHeight: 280, minWidth: 220),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
          onSelected: (val) {
            widget.controller.text = val;
            widget.onSelected?.call(val);
            if (mounted) setState(() {});
          },
          itemBuilder: (ctx) {
            final standard = FeeService.defaultFeeTitles;
            final pastCustom = _items.where((it) => !standard.contains(it)).toList();

            final menuEntries = <PopupMenuEntry<String>>[];

            for (final title in standard) {
              final isSelected = widget.controller.text.trim().toLowerCase() == title.trim().toLowerCase();
              menuEntries.add(
                PopupMenuItem<String>(
                  value: title,
                  height: 38,
                  child: Row(
                    children: [
                      Icon(
                        _getIconForTitle(title),
                        size: 16,
                        color: isSelected ? effectivePrimary : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? effectivePrimary : effectiveText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: effectivePrimary,
                        ),
                    ],
                  ),
                ),
              );
            }

            if (pastCustom.isNotEmpty) {
              menuEntries.add(const PopupMenuDivider(height: 8));
              menuEntries.add(
                const PopupMenuItem<String>(
                  enabled: false,
                  height: 24,
                  child: Text(
                    'PREVIOUSLY CREATED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              );

              for (final title in pastCustom) {
                final isSelected = widget.controller.text.trim().toLowerCase() == title.trim().toLowerCase();
                menuEntries.add(
                  PopupMenuItem<String>(
                    value: title,
                    height: 38,
                    child: Row(
                      children: [
                        Icon(
                          _getIconForTitle(title),
                          size: 16,
                          color: isSelected ? effectivePrimary : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? effectivePrimary : effectiveText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: effectivePrimary,
                          ),
                      ],
                    ),
                  ),
                );
              }
            }

            return menuEntries;
          },
        ),
      ),
    );
  }
}
