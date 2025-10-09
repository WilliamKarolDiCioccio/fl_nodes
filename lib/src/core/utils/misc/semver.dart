/// Semantic versioning: (major, minor, patch, hotfix - 0.5.0+1)
typedef SemVer = (int major, int minor, int patch, int? hotfix);

class SemVerUtils {
  /// Parses a semantic version string into a [SemVer] tuple.
  SemVer parse(String input) {
    final regex = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$');
    final match = regex.firstMatch(input);

    if (match == null) {
      throw FormatException('Invalid semantic version format: $input');
    }

    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    final patch = int.parse(match.group(3)!);

    final hotfix = match.group(4) != null ? int.parse(match.group(4)!) : null;

    return (major, minor, patch, hotfix);
  }

  /// Behaves like compareTo
  int compare(SemVer a, SemVer b) {
    final (aMajor, aMinor, aPatch, aHotfix) = a;
    final (bMajor, bMinor, bPatch, bHotfix) = b;

    if (aMajor != bMajor) return aMajor.compareTo(bMajor);
    if (aMinor != bMinor) return aMinor.compareTo(bMinor);
    if (aPatch != bPatch) return aPatch.compareTo(bPatch);

    if (aHotfix == null && bHotfix == null) return 0;
    if (aHotfix == null) return 1; // a is greater (no hotfix)
    if (bHotfix == null) return -1; // b is greater (no hotfix)

    return aHotfix.compareTo(bHotfix);
  }
}
