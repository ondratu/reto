#!/usr/bin/env bash
# Build a portable Windows ZIP of Reto. Run it in an MSYS2 shell (UCRT64 or
# CLANGARM64) with the dependencies installed, see
# .github/workflows/windows.yml.
#
# Usage: tools/build-windows.sh [ARCH] [OUTPUT_DIR] [BUILD_DIR]
#
# ARCH is only used in the file name (default: x86_64). The ZIP is written to
# OUTPUT_DIR (default: dist) as cz.zeropage.Reto-windows-<ARCH>.zip.
#
# BUILD_DIR is a Meson build directory that is already built, the one the
# tests ran in. It is installed as it is, without compiling again. It must be
# at the same absolute path as when it was built. Without it the program is
# built here, as a release.
set -euo pipefail

app_id=cz.zeropage.Reto
root=$(cd "$(dirname "$0")/.." && pwd)
arch=${1:-x86_64}
out=${2:-$root/dist}
build=${3:-}
work=$root/.windows
destdir=$work/install
stage=$work/Reto

rm -rf "$work"
mkdir -p "$out" "$destdir"
# The ZIP is made from another directory, so the path must not be relative.
out=$(cd "$out" && pwd)

if [ -n "$build" ]; then
    meson install -C "$build" --no-rebuild --destdir "$destdir"
else
    meson setup "$work/build" "$root" --buildtype=release
    meson install -C "$work/build" --destdir "$destdir"
fi
# The files are under the whole prefix of the build, which is the one of
# MSYS2 (like /ucrt64) without the drive. Take that as the package.
exe=$(find "$destdir" -name reto.exe | head -n 1)
if [ -z "$exe" ]; then
    echo "reto.exe was not installed to $destdir" >&2
    exit 1
fi
mv "$(dirname "$(dirname "$exe")")" "$stage"

# Runtime files of GTK that are looked up at run time, not linked
share=$MSYSTEM_PREFIX/share
mkdir -p "$stage/share/glib-2.0/schemas" "$stage/share/icons"
# Only the schemas of GTK and of the application, not of every package.
cp "$share"/glib-2.0/schemas/org.gtk.gtk4.*.gschema.xml \
    "$share"/glib-2.0/schemas/$app_id.*gschema.xml \
    "$stage/share/glib-2.0/schemas/" 2>/dev/null || true
if compgen -G "$stage/share/glib-2.0/schemas/*.gschema.xml" >/dev/null; then
    glib-compile-schemas "$stage/share/glib-2.0/schemas"
fi
for theme in Adwaita hicolor; do
    if [ -d "$share/icons/$theme" ]; then
        cp -r "$share/icons/$theme" "$stage/share/icons/"
    fi
done

# Image loaders (SVG icons), with a cache relative to the program. The tool
# writes absolute paths, with slashes or with escaped backslashes.
loaders=$MSYSTEM_PREFIX/lib/gdk-pixbuf-2.0
if [ -d "$loaders" ]; then
    mkdir -p "$stage/lib"
    cp -r "$loaders" "$stage/lib/"
    cache_dir=$stage/lib/gdk-pixbuf-2.0/2.10.0
    GDK_PIXBUF_MODULEDIR=$cache_dir/loaders gdk-pixbuf-query-loaders \
        | sed -e 's|\\\\|/|g' \
        | sed -e 's|"[^"]*/lib/gdk-pixbuf-2.0/|"lib/gdk-pixbuf-2.0/|' \
        > "$cache_dir/loaders.cache"
fi

# Shared libraries of the program and of the loaders. The paths of ldd are
# converted, as they may be written the Windows way.
{
    ldd "$stage/bin/reto.exe"
    find "$stage/lib" -name '*.dll' -exec ldd {} + 2>/dev/null || true
} | awk '/=>/ {print $3}' | sort -u | while read -r dll; do
    dll=$(cygpath -u "$dll")
    case "$dll" in
        "$MSYSTEM_PREFIX"/*) cp -n "$dll" "$stage/bin/" ;;
    esac
done
if ! compgen -G "$stage/bin/libgtk-4-*.dll" >/dev/null; then
    echo "The libraries were not copied to $stage/bin" >&2
    exit 1
fi

# Run the program with nothing but the package and Windows itself, so a
# library that is missing fails here and not on the computer of the user.
# --help needs no display, the program prints it and exits.
PATH="$stage/bin:$(cygpath -u "$SYSTEMROOT")/System32" \
    "$stage/bin/reto.exe" --help >/dev/null

(cd "$work" && zip -qr "$out/$app_id-windows-$arch.zip" Reto)
echo "Built $out/$app_id-windows-$arch.zip"
