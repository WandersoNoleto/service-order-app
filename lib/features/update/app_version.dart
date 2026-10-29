/// A release version as published on GitHub.
///
/// Tags: `v1.2.3` (generic channel) or `v1.2.3-val.4` (client channel "val").
/// [code] follows the same formula as tool/build_release.sh, so it can be
/// compared with the installed app's versionCode.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch, [this.build = 0]);

  final int major;
  final int minor;
  final int patch;

  /// Client build number (1-99); 0 for the generic channel.
  final int build;

  int get code => major * 1000000 + minor * 10000 + patch * 100 + build;

  /// "1.2.3" (generic) or "1.2.3 (4)" (client build).
  String get label => build == 0 ? '$major.$minor.$patch' : '$major.$minor.$patch ($build)';

  /// Parses [tag] only if it belongs to [channel] ("" = generic).
  static AppVersion? parseTag(String tag, {required String channel}) {
    final pattern = channel.isEmpty
        ? RegExp(r'^v(\d+)\.(\d+)\.(\d+)$')
        : RegExp('^v(\\d+)\\.(\\d+)\\.(\\d+)-${RegExp.escape(channel)}\\.(\\d+)\$');

    final match = pattern.firstMatch(tag);
    if (match == null) return null;

    final numbers = [
      for (var i = 1; i <= match.groupCount; i++) int.parse(match.group(i)!),
    ];
    return AppVersion(
      numbers[0],
      numbers[1],
      numbers[2],
      numbers.length > 3 ? numbers[3] : 0,
    );
  }

  @override
  int compareTo(AppVersion other) => code.compareTo(other.code);
}
