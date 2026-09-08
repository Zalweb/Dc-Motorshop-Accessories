/// App version details and repository metadata.
abstract final class AppVersion {
  /// Current semver version string of the app (matches pubspec.yaml).
  static const String current = '1.2.2';

  /// Current build number (matches pubspec.yaml build suffix).
  static const int buildNumber = 5;

  /// Full version display string: `v1.2.0 (Build 3)`
  static const String displayVersion = 'v$current (Build $buildNumber)';

  /// Semver version with build number: `1.2.0+3`
  static const String currentWithBuild = '$current+$buildNumber';

  /// Git release tag corresponding to this release: `v1.2.0`
  static const String tag = 'v$current';

  /// GitHub repository owner.
  static const String githubOwner = 'Zalweb';

  /// GitHub repository name.
  static const String githubRepo = 'Dc-Motorshop-Accessories';

  /// GitHub API endpoint for querying the latest release metadata.
  static const String latestReleaseApiUrl =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  /// Public web page listing all GitHub releases.
  static const String releasesUrl =
      'https://github.com/Zalweb/$githubRepo/releases';

  /// Live production web app URL.
  static const String webProductionUrl = 'https://dcmotorshop.mospams.shop';
}
