import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:strawberry/features/about/privacy_policy_page.dart';

/// Opens the Strawberry Preschool Privacy & Data Policy.
///
/// If a [BuildContext] is provided (or when running on mobile app), it pushes
/// the native in-app [PrivacyPolicyPage] with a non-fixed, smooth-scrolling navbar.
///
/// On Web fallback: Navigates to `/privacy` in the SAME tab/window (`_self`).
/// On Mobile Apps fallback: Opens `https://strawberrydaycare.co.in/privacy` in the browser.
Future<void> openPrivacyPolicy([BuildContext? context]) async {
  if (context != null && context.mounted) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PrivacyPolicyPage(),
      ),
    );
    return;
  }

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
