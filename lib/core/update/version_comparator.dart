import 'package:flutter/foundation.dart';

/// Structured semantic version supporting `v1.2.0`, `1.2.0+3`, etc.
@immutable
class AppSemanticVersion implements Comparable<AppSemanticVersion> {
  const AppSemanticVersion({
    this.major = 0,
    this.minor = 0,
    this.patch = 0,
    this.build = 0,
    this.preRelease,
    required this.raw,
  });

  final int major;
  final int minor;
  final int patch;
  final int build;
  final String? preRelease;
  final String raw;

  /// Parses a version string into an [AppSemanticVersion].
  ///
  /// Examples:
  /// - `"v1.2.0"` -> 1.2.0
  /// - `"1.2.0+3"` -> 1.2.0 build 3
  /// - `"v1.3.0+10"` -> 1.3.0 build 10
  /// - `"2.0"` -> 2.0.0
  factory AppSemanticVersion.parse(String versionString) {
    final trimmed = versionString.trim();
    // Strip leading 'v' or 'V'
    final noV = trimmed.replaceFirst(RegExp(r'^[vV]'), '');

    // Split build number if present (+3)
    final buildParts = noV.split('+');
    final versionCore = buildParts[0];
    final int buildNumber = buildParts.length > 1
        ? int.tryParse(buildParts[1]) ?? 0
        : 0;

    // Split pre-release if present (-beta, -rc1)
    final preReleaseParts = versionCore.split('-');
    final numbers = preReleaseParts[0].split('.');
    final preRelease = preReleaseParts.length > 1 ? preReleaseParts[1] : null;

    final major = numbers.isNotEmpty ? int.tryParse(numbers[0]) ?? 0 : 0;
    final minor = numbers.length > 1 ? int.tryParse(numbers[1]) ?? 0 : 0;
    final patch = numbers.length > 2 ? int.tryParse(numbers[2]) ?? 0 : 0;

    return AppSemanticVersion(
      major: major,
      minor: minor,
      patch: patch,
      build: buildNumber,
      preRelease: preRelease,
      raw: versionString,
    );
  }

  /// Returns true if this version is strictly greater than [other].
  bool isNewerThan(AppSemanticVersion other) => compareTo(other) > 0;

  @override
  int compareTo(AppSemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    // Normal version has higher precedence than pre-release version
    // (e.g. 1.3.0 is newer than 1.3.0-beta)
    if (preRelease == null && other.preRelease != null) return 1;
    if (preRelease != null && other.preRelease == null) return -1;
    if (preRelease != null && other.preRelease != null) {
      final preComp = _comparePreRelease(preRelease!, other.preRelease!);
      if (preComp != 0) return preComp;
    }

    // When major, minor, patch, and preRelease are identical, compare build numbers.
    // In mobile releases, 1.2.0+1 is strictly newer than 1.2.0 (build 0).
    if (build != other.build) return build.compareTo(other.build);

    return 0;
  }

  static int _comparePreRelease(String a, String b) {
    final aParts = a.split('.');
    final bParts = b.split('.');
    final minLength = aParts.length < bParts.length ? aParts.length : bParts.length;

    for (var i = 0; i < minLength; i++) {
      final aPart = aParts[i];
      final bPart = bParts[i];
      final aNum = int.tryParse(aPart);
      final bNum = int.tryParse(bPart);

      if (aNum != null && bNum != null) {
        if (aNum != bNum) return aNum.compareTo(bNum);
      } else if (aNum != null && bNum == null) {
        return -1; // Numeric identifiers have lower precedence than non-numeric
      } else if (aNum == null && bNum != null) {
        return 1;
      } else {
        final comp = aPart.compareTo(bPart);
        if (comp != 0) return comp;
      }
    }
    return aParts.length.compareTo(bParts.length);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSemanticVersion &&
          runtimeType == other.runtimeType &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch &&
          build == other.build &&
          preRelease == other.preRelease;

  @override
  int get hashCode => Object.hash(major, minor, patch, build, preRelease);

  @override
  String toString() {
    final base = '$major.$minor.$patch';
    final withPre = preRelease != null ? '$base-$preRelease' : base;
    return build > 0 ? '$withPre+$build' : withPre;
  }
}

/// Helper utility for version comparison checks.
abstract final class VersionComparator {
  /// Returns `true` if [latest] is strictly newer than [current].
  static bool isUpdateAvailable({
    required String current,
    required String latest,
  }) {
    final currentSem = AppSemanticVersion.parse(current);
    final latestSem = AppSemanticVersion.parse(latest);
    return latestSem.isNewerThan(currentSem);
  }

  /// Compares two version strings. Returns:
  /// - negative if v1 < v2
  /// - zero if v1 == v2
  /// - positive if v1 > v2
  static int compare(String v1, String v2) {
    return AppSemanticVersion.parse(v1).compareTo(AppSemanticVersion.parse(v2));
  }
}
