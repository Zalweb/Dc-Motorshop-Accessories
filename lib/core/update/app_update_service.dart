import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/app_version.dart';
import '../supabase/supabase_service.dart';
import 'app_update_info.dart';
import 'version_comparator.dart';

/// Service responsible for querying GitHub Releases API (and Supabase fallback)
/// to detect application updates safely across Web and Native platforms.
class AppUpdateService {
  AppUpdateService({
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;

  AppUpdateInfo? _cachedInfo;
  DateTime? _lastCheckTime;

  /// Cooldown duration for automated background update checks to prevent rate limiting.
  static const Duration backgroundCheckCooldown = Duration(minutes: 30);

  /// Retrieves the current app semver string and build number.
  /// Uses [PackageInfo] on supported platforms with graceful fallback to [AppVersion.current].
  Future<({String version, int buildNumber})> getCurrentVersion() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final version = pkg.version.isNotEmpty ? pkg.version : AppVersion.current;
      final buildNumber = int.tryParse(pkg.buildNumber) ?? AppVersion.buildNumber;
      return (version: version, buildNumber: buildNumber);
    } catch (_) {
      return (version: AppVersion.current, buildNumber: AppVersion.buildNumber);
    }
  }

  /// Checks for app updates.
  ///
  /// Set [force] to true to bypass cache (e.g. when triggered by user action).
  Future<AppUpdateInfo?> checkForUpdate({bool force = false}) async {
    // Check cache cooldown if not forcing
    if (!force && _cachedInfo != null && _lastCheckTime != null) {
      final elapsed = DateTime.now().difference(_lastCheckTime!);
      if (elapsed < backgroundCheckCooldown) {
        return _cachedInfo;
      }
    }

    final current = await getCurrentVersion();

    // 1. Check GitHub Releases API
    try {
      final info = await _fetchFromGitHub(
        currentVersion: current.version,
        currentBuild: current.buildNumber,
      );
      if (info != null) {
        _cachedInfo = info;
        _lastCheckTime = DateTime.now();
        return info;
      }
    } catch (e) {
      debugPrint('[AppUpdateService] GitHub check failed: $e');
    }

    // 2. Fallback to Supabase remote config if GitHub fails / rate-limited
    try {
      final info = await _fetchFromSupabase(
        currentVersion: current.version,
        currentBuild: current.buildNumber,
      );
      if (info != null) {
        _cachedInfo = info;
        _lastCheckTime = DateTime.now();
        return info;
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Supabase fallback check failed: $e');
    }

    // Return previous cached result if available, or null when network check could not be completed
    return _cachedInfo;
  }

  /// Fetches release metadata from GitHub API.
  Future<AppUpdateInfo?> _fetchFromGitHub({
    required String currentVersion,
    required int currentBuild,
  }) async {
    final uri = Uri.parse(AppVersion.latestReleaseApiUrl);
    final response = await _http.get(
      uri,
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'MoSPAMS-App/$currentVersion',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return parseReleaseJson(
        json,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      );
    } else {
      debugPrint('[AppUpdateService] GitHub returned status ${response.statusCode}');
      return null;
    }
  }

  /// Fetches release metadata from Supabase `app_releases` table if configured.
  Future<AppUpdateInfo?> _fetchFromSupabase({
    required String currentVersion,
    required int currentBuild,
  }) async {
    try {
      final client = SupabaseService.client;
      final response = await client
          .from('app_releases')
          .select()
          .order('published_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final tagName = (response['tag_name'] as String?) ?? (response['version'] as String?) ?? '';
      final cleanLatest = tagName.replaceFirst(RegExp(r'^[vV]'), '');
      final name = (response['name'] as String?) ?? 'v$cleanLatest';
      final notes = (response['notes'] as String?) ?? (response['body'] as String?) ?? '';
      final apkUrl = response['apk_url'] as String?;
      final releaseUrl = (response['html_url'] as String?) ?? AppVersion.releasesUrl;
      final isMandatory = (response['is_mandatory'] as bool?) ?? false;

      final currentComp = currentBuild > 0 ? '$currentVersion+$currentBuild' : currentVersion;
      final hasUpdate = VersionComparator.isUpdateAvailable(
        current: currentComp,
        latest: cleanLatest,
      );

      return AppUpdateInfo(
        currentVersion: currentComp,
        latestVersion: cleanLatest,
        hasUpdate: hasUpdate,
        releaseName: name,
        releaseNotes: notes,
        apkDownloadUrl: apkUrl,
        releasePageUrl: releaseUrl,
        isMandatory: isMandatory,
      );
    } catch (e) {
      debugPrint('[AppUpdateService] Supabase fallback query failed: $e');
      return null;
    }
  }

  /// Parses a GitHub Release JSON object into an [AppUpdateInfo].
  static AppUpdateInfo parseReleaseJson(
    Map<String, dynamic> json, {
    required String currentVersion,
    int currentBuild = 0,
  }) {
    final tagName = (json['tag_name'] as String?) ?? '';
    final cleanLatestVersion = tagName.replaceFirst(RegExp(r'^[vV]'), '');
    final releaseName = (json['name'] as String?) ?? 'Release $tagName';
    final releaseNotes = (json['body'] as String?) ?? '';
    final releasePageUrl = (json['html_url'] as String?) ?? AppVersion.releasesUrl;
    final isDraft = (json['draft'] as bool?) ?? false;

    final currentComp = currentBuild > 0 ? '$currentVersion+$currentBuild' : currentVersion;
    if (isDraft) {
      return AppUpdateInfo(
        currentVersion: currentComp,
        latestVersion: cleanLatestVersion.isNotEmpty ? cleanLatestVersion : currentComp,
        hasUpdate: false,
        releaseName: releaseName,
        releaseNotes: releaseNotes,
        releasePageUrl: releasePageUrl,
      );
    }

    DateTime? publishedAt;
    if (json['published_at'] != null) {
      publishedAt = DateTime.tryParse(json['published_at'] as String);
    }

    // Locate Android APK in assets
    String? apkUrl;
    int? apkSize;
    final assets = json['assets'] as List<dynamic>?;
    if (assets != null) {
      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final name = (asset['name'] as String?)?.toLowerCase() ?? '';
          final contentType = (asset['content_type'] as String?)?.toLowerCase() ?? '';
          if (name.endsWith('.apk') || contentType.contains('android.package-archive')) {
            apkUrl = asset['browser_download_url'] as String?;
            apkSize = asset['size'] as int?;
            break;
          }
        }
      }
    }

    final isMandatory = releaseNotes.toUpperCase().contains('[MANDATORY]') ||
        releaseNotes.toUpperCase().contains('[CRITICAL]');

    final hasUpdate = VersionComparator.isUpdateAvailable(
      current: currentComp,
      latest: cleanLatestVersion,
    );

    return AppUpdateInfo(
      currentVersion: currentComp,
      latestVersion: cleanLatestVersion,
      hasUpdate: hasUpdate,
      releaseName: releaseName,
      releaseNotes: releaseNotes,
      apkDownloadUrl: apkUrl,
      releasePageUrl: releasePageUrl,
      publishedAt: publishedAt,
      isMandatory: isMandatory,
      apkSizeBytes: apkSize,
    );
  }
}
