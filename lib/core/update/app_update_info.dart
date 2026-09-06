import 'package:flutter/foundation.dart';

/// Representation of an available software update for the app.
@immutable
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    required this.releaseName,
    required this.releaseNotes,
    this.apkDownloadUrl,
    required this.releasePageUrl,
    this.publishedAt,
    this.isMandatory = false,
    this.apkSizeBytes,
    this.isDismissed = false,
  });

  /// Currently running version (e.g. `'1.2.0'`).
  final String currentVersion;

  /// Latest available version tag or string (e.g. `'1.3.0'`).
  final String latestVersion;

  /// Whether [latestVersion] is strictly newer than [currentVersion].
  final bool hasUpdate;

  /// Title or name of the release (e.g. `'MoSPAMS v1.3.0'`).
  final String releaseName;

  /// Changelog / release description text (Markdown formatted).
  final String releaseNotes;

  /// Direct APK download URL if present in release assets.
  final String? apkDownloadUrl;

  /// Web URL for the release on GitHub.
  final String releasePageUrl;

  /// When this release was published.
  final DateTime? publishedAt;

  /// Whether this update is critical/mandatory.
  final bool isMandatory;

  /// Byte size of the APK asset, if known.
  final int? apkSizeBytes;

  /// Whether the user dismissed this release notification.
  final bool isDismissed;

  /// Helper returning a human-readable file size (e.g. `"82.3 MB"`).
  String? get formattedApkSize {
    if (apkSizeBytes == null || apkSizeBytes! <= 0) return null;
    final mb = apkSizeBytes! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Cleaned release notes summary without markdown headers, bold, or raw link syntax.
  String get cleanReleaseNotes {
    if (releaseNotes.trim().isEmpty) {
      return 'Performance improvements and bug fixes.';
    }
    var text = releaseNotes.trim();
    // Strip markdown headers (e.g. ### Header -> Header)
    text = text.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    // Strip markdown bold and italic formatting
    text = text.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m[1] ?? '');
    text = text.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m[1] ?? '');
    // Strip markdown link syntax [Text](url) -> Text
    text = text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1] ?? '');
    return text.trim();
  }

  AppUpdateInfo copyWith({
    String? currentVersion,
    String? latestVersion,
    bool? hasUpdate,
    String? releaseName,
    String? releaseNotes,
    String? apkDownloadUrl,
    String? releasePageUrl,
    DateTime? publishedAt,
    bool? isMandatory,
    int? apkSizeBytes,
    bool? isDismissed,
  }) {
    return AppUpdateInfo(
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      releaseName: releaseName ?? this.releaseName,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      apkDownloadUrl: apkDownloadUrl ?? this.apkDownloadUrl,
      releasePageUrl: releasePageUrl ?? this.releasePageUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      isMandatory: isMandatory ?? this.isMandatory,
      apkSizeBytes: apkSizeBytes ?? this.apkSizeBytes,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  @override
  String toString() =>
      'AppUpdateInfo(current: $currentVersion, latest: $latestVersion, hasUpdate: $hasUpdate, apk: $apkDownloadUrl)';
}
