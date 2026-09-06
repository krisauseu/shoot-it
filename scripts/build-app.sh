#!/bin/zsh
set -euo pipefail

configuration="${1:-release}"
root_dir="${0:A:h:h}"
bundle_dir="$root_dir/.build/Shoot It.app"
binary_dir="$root_dir/.build/$configuration"
module_cache_dir="$root_dir/.build/swiftpm-module-cache"

cd "$root_dir"
env CLANG_MODULE_CACHE_PATH="$root_dir/.build/clang-module-cache" \
    SWIFTPM_MODULECACHE_OVERRIDE="$module_cache_dir" \
    swift build --disable-sandbox -c "$configuration"

mkdir -p "$bundle_dir/Contents/MacOS" "$bundle_dir/Contents/Resources"
cp "$binary_dir/ShootIt" "$bundle_dir/Contents/MacOS/ShootIt"
cp "$root_dir/Resources/Info.plist" "$bundle_dir/Contents/Info.plist"
codesign --force --deep --sign - "$bundle_dir"

print "$bundle_dir"
