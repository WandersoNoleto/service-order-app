#!/usr/bin/env bash
# Builds a signed release APK for one flavor, ready to attach to a GitHub
# release. The version comes from pubspec.yaml (`version: 1.0.1+1000100`).
#
#   tool/build_release.sh standard      -> tag v1.0.1        (generic)
#   tool/build_release.sh val 2         -> tag v1.0.1-val.2  (client)
#
# versionCode = major*1000000 + minor*10000 + patch*100 + build, so it always
# grows (Android refuses updates with a lower or equal versionCode). The
# auto-update computes the same number from the tag.
set -euo pipefail

usage() {
  echo "usage: $0 standard" >&2
  echo "       $0 val <build 1-99>" >&2
  exit 1
}

[[ $# -ge 1 ]] || usage
flavor=$1
build=${2:-0}

# --- Version from pubspec.yaml -------------------------------------------
pubspec_version=$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml)
[[ $pubspec_version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)$ ]] ||
  { echo "pubspec.yaml version must look like 1.0.1+1000100 (got '$pubspec_version')" >&2; exit 1; }
major=${BASH_REMATCH[1]}
minor=${BASH_REMATCH[2]}
patch=${BASH_REMATCH[3]}
pubspec_code=${BASH_REMATCH[4]}
version="$major.$minor.$patch"

base_code=$((major * 1000000 + minor * 10000 + patch * 100))
[[ $pubspec_code == "$base_code" ]] ||
  { echo "pubspec.yaml: version $version must be $version+$base_code (got +$pubspec_code)" >&2; exit 1; }

# --- Flavor ---------------------------------------------------------------
case $flavor in
  standard)
    [[ $build == 0 ]] || { echo "standard builds have no build number" >&2; exit 1; }
    config=clients/default/config.json
    tag="v$version"
    ;;
  val)
    [[ $build =~ ^[0-9]+$ && $build -ge 1 && $build -le 99 ]] ||
      { echo "val builds need a build number from 1 to 99" >&2; exit 1; }
    config=clients/private/val/config.json
    tag="v$version-val.$build"
    ;;
  *) usage ;;
esac

[[ -f android/key.properties ]] ||
  { echo "android/key.properties is missing (see android/key.properties.example)" >&2; exit 1; }

if [[ -n $(git status --porcelain) ]]; then
  echo "warning: uncommitted changes — this APK won't match any commit" >&2
fi

version_code=$((base_code + build))

flutter build apk --release \
  --flavor "$flavor" \
  --dart-define-from-file="$config" \
  --build-name="$version" \
  --build-number="$version_code"

mkdir -p build/release
apk="build/release/service-order-app-${tag#v}.apk"
cp "build/app/outputs/flutter-apk/app-$flavor-release.apk" "$apk"

echo
echo "Tag:          $tag"
echo "versionCode:  $version_code"
echo "Commit:       $(git rev-parse --short HEAD)"
echo "APK:          $apk"
