#!/usr/bin/env bash
# Build a portable Windows ZIP of Reto. Run it in an MSYS2 shell (UCRT64 or
# CLANGARM64) with the dependencies installed, see
# .github/workflows/windows.yml.
#
# Usage: tools/build-windows.sh [ARCH] [OUTPUT_DIR]
#
# ARCH is only used in the file name (default: x86_64). The ZIP is written to
# OUTPUT_DIR (default: dist) as cz.zeropage.Reto-windows-<ARCH>.zip.
set -euo pipefail

app_id=cz.zeropage.Reto
root=$(cd "$(dirname "$0")/.." && pwd)
arch=${1:-x86_64}
out=${2:-$root/dist}
work=$root/.windows
stage=$work/Reto

rm -rf "$work"
mkdir -p "$out" "$stage"

meson setup "$work/build" "$root" --prefix="$stage" --buildtype=release
meson install -C "$work/build" --no-rebuild

# Runtime files of GTK that are looked up at run time, not linked
share=$MSYSTEM_PREFIX/share
mkdir -p "$stage/share/glib-2.0/schemas" "$stage/share/icons"
cp "$share"/glib-2.0/schemas/*.gschema.xml "$stage/share/glib-2.0/schemas/"
glib-compile-schemas "$stage/share/glib-2.0/schemas"
for theme in Adwaita hicolor; do
    if [ -d "$share/icons/$theme" ]; then
        cp -r "$share/icons/$theme" "$stage/share/icons/"
    fi
done

# Image loaders (SVG icons), with a cache relative to the program
loaders=$MSYSTEM_PREFIX/lib/gdk-pixbuf-2.0
if [ -d "$loaders" ]; then
    mkdir -p "$stage/lib"
    cp -r "$loaders" "$stage/lib/"
    GDK_PIXBUF_MODULEDIR=$stage/lib/gdk-pixbuf-2.0/2.10.0/loaders \
        gdk-pixbuf-query-loaders \
        | sed "s|$(cygpath -m "$stage")/||g" \
        > "$stage/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
fi

# Shared libraries of the program and of the loaders
{
    ldd "$stage/bin/reto.exe"
    find "$stage/lib" -name '*.dll' -exec ldd {} + 2>/dev/null || true
} | awk '/=>/ {print $3}' | grep -i "^$MSYSTEM_PREFIX/" | sort -u \
    | while read -r dll; do cp -n "$dll" "$stage/bin/"; done

(cd "$work" && zip -qr "$out/$app_id-windows-$arch.zip" Reto)
echo "Built $out/$app_id-windows-$arch.zip"
