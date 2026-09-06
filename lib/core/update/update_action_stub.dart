import 'package:url_launcher/url_launcher.dart';
import 'app_update_info.dart';

/// Native (Android/iOS/Desktop) implementation for triggering an update.
///
/// On Android, opening the direct APK download URL in the external browser or
/// system download manager initiates the APK download. Android's Package Installer
/// automatically handles in-place upgrades upon opening the downloaded APK,
/// preserving 100% of the app's internal database (Isar) and SharedPreferences data.
Future<bool> triggerPlatformUpdate(AppUpdateInfo info) async {
  final targetUrl = (info.apkDownloadUrl != null && info.apkDownloadUrl!.isNotEmpty)
      ? info.apkDownloadUrl!
      : info.releasePageUrl;

  try {
    final uri = Uri.parse(targetUrl);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
