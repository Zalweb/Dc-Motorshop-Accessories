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
    // 1. Unregister active service workers so old cached bundles are not served
    final sw = html.window.navigator.serviceWorker;
    if (sw != null) {
      final registrations = await sw.getRegistrations();
      for (final reg in registrations) {
        await reg.unregister();
      }
    }

    // 2. Clear Cache Storage
    final caches = html.window.caches;
    if (caches != null) {
      final keys = await caches.keys();
      for (final key in keys) {
        await caches.delete(key);
      }
    }

    // 3. Force reload with cache-busting query parameter
    final currentUri = Uri.parse(html.window.location.href);
    final cacheBustUri = currentUri.replace(
      queryParameters: {
        ...currentUri.queryParameters,
        '_v': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    html.window.location.replace(cacheBustUri.toString());
    return true;
  } catch (_) {
    try {
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
}
