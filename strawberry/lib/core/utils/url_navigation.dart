import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Opens the Strawberry Preschool Privacy & Data Policy.
///
/// On Web: Navigates to `/privacy` in the SAME tab/window (`_self`) so users don't get
/// kicked out into a new tab while browsing the website.
/// On Mobile Apps: Opens `https://strawberrydaycare.co.in/privacy` in the external browser.
Future<void> openPrivacyPolicy() async {
  try {
    if (kIsWeb) {
      final uri = Uri.base.resolve('/privacy');
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_self',
      );
    } else {
      final uri = Uri.parse('https://strawberrydaycare.co.in/privacy');
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  } catch (_) {
    try {
      final fallbackUri = Uri.parse('https://strawberrydaycare.co.in/privacy');
      await launchUrl(
        fallbackUri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: kIsWeb ? '_self' : null,
      );
    } catch (_) {}
  }
}
