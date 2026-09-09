import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class StudentAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;
  final double? fontSize;
  final Border? border;

  const StudentAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.size = 38,
    this.fontSize,
    this.border,
  });

  /// Transform Google user content URLs on Web to bypass CanvasKit CORS block
  static String sanitizeUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (kIsWeb) {
      if (trimmed.contains('googleusercontent.com') ||
          trimmed.contains('ggpht.com')) {
        return 'https://images.weserv.nl/?url=${Uri.encodeComponent(trimmed)}';
      }
    }
    return trimmed;
  }

  /// Deterministic pastel gradient based on student's name
  List<Color> _getGradientForName(String name) {
    final colors = [
      [const Color(0xFFF43F5E), const Color(0xFFFB7185)], // Rose
      [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)], // Violet
      [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)], // Sky
      [const Color(0xFF10B981), const Color(0xFF34D399)], // Emerald
      [const Color(0xFFF59E0B), const Color(0xFFFBBF24)], // Amber
      [const Color(0xFFEC4899), const Color(0xFFF472B6)], // Pink
      [const Color(0xFF6366F1), const Color(0xFF818CF8)], // Indigo
      [const Color(0xFF14B8A6), const Color(0xFF2DD4BF)], // Teal
    ];
    if (name.isEmpty) return colors.first;
    final code = name.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    return colors[code % colors.length];
  }

  Widget _buildFallbackLetter() {
    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '🍓';
    final gradient = _getGradientForName(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize ?? (size * 0.42),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = sanitizeUrl(photoUrl);

    Widget inner;
    if (cleanUrl.isEmpty) {
      inner = _buildFallbackLetter();
    } else {
      inner = Image.network(
        cleanUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackLetter();
        },
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
      ),
      child: ClipOval(child: inner),
    );
  }
}
