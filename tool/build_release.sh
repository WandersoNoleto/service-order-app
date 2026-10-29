#!/usr/bin/env bash
# Builds a signed release APK for one flavor, ready to attach to a GitHub
# release.
#
#   tool/build_release.sh standard 1.0.1      -> tag v1.0.1        (generic)
#   tool/build_release.sh val 1.0.1 2         -> tag v1.0.1-val.2  (client)
#
# versionCode = major*1000000 + minor*10000 + patch*100 + build, so it always
# grows (Android refuses updates with a lower or equal versionCode). The
# auto-update computes the same number from the tag.
set -euo pipefail

usage() {
  echo "usage: $0 <standard|val> <major.minor.patch> [build 1-99, val only]" >&2
  exit 1
}

[[ $# -ge 2 ]] || usage
flavor=$1
version=$2
build=${3:-0}

[[ $version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || usage
major=${BASH_REMATCH[1]}
minor=${BASH_REMATCH[2]}
patch=${BASH_REMATCH[3]}

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

version_code=$((major * 1000000 + minor * 10000 + patch * 100 + build))

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
echo "APK:          $apk"
