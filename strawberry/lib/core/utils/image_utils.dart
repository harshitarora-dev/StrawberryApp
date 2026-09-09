import 'package:flutter/foundation.dart';

class AppImageUtils {
  /// Optimizes image URLs for Web to:
  /// 1. Prevent WebGL texture overflow on mobile browsers (mobile GPUs have MAX_TEXTURE_SIZE=4096;
  ///    camera photos are often 4160px+ high, causing CanvasKit to render them as solid black).
  /// 2. Drastically reduce bandwidth (converting 3-10MB raw camera photos into 30-70KB WebP).
  /// 3. Bypass CanvasKit CORS blocks (Google profile photos, Supabase storage).
  static String optimize(String? url, {int maxWidth = 800, int quality = 85}) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();

    // On native mobile (Android / iOS), Flutter's Skia handles large images without WebGL limits
    if (!kIsWeb) {
      return trimmed;
    }

    // Only proxy images that need CORS bypass or downscaling (Supabase Storage, Google Photos)
    if (trimmed.contains('supabase.co') ||
        trimmed.contains('googleusercontent.com') ||
        trimmed.contains('ggpht.com')) {
      final encoded = Uri.encodeComponent(trimmed);
      return 'https://images.weserv.nl/?url=$encoded&w=$maxWidth&q=$quality&output=webp';
    }

    return trimmed;
  }

  /// Converts an internal Supabase storage URL into an official branded website URL
  /// e.g. https://tbsmesdqigeajrwswlkj.supabase.co/storage/v1/object/public/gallery/123_abc.jpg
  /// -> https://strawberrydaycare.co.in/photos/123_abc.jpg
  /// Handled seamlessly via reverse-proxy in vercel.json.
  static String getPublicShareUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();

    if (trimmed.contains('supabase.co') && trimmed.contains('/gallery/')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        final fileName = uri.pathSegments.last;
        final host = kIsWeb &&
                Uri.base.host.isNotEmpty &&
                !Uri.base.host.contains('localhost') &&
                !Uri.base.host.contains('127.0.0.1')
            ? Uri.base.host
            : 'strawberrydaycare.co.in';
        return 'https://$host/photos/$fileName';
      }
    }
    return trimmed;
  }
}
