// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:url_launcher/url_launcher.dart';
import 'app_update_info.dart';

/// Web implementation for triggering an update.
///
/// On Web, reloading the browser window refreshes the cached bundle,
/// service worker, and assets to load the newly published release.
Future<bool> triggerPlatformUpdate(AppUpdateInfo info) async {
  try {
    // Reload the active window to load the latest published build
    html.window.location.reload();
    return true;
  } catch (_) {
    final uri = Uri.parse(info.releasePageUrl);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
    return false;
  }
}
