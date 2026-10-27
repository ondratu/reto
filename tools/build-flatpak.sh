#!/usr/bin/env bash
# Build a single-file Flatpak bundle from flatpak/cz.zeropage.Reto.yaml.
#
# Usage: tools/build-flatpak.sh [ARCH] [OUTPUT_DIR]
#
# ARCH is x86_64 or aarch64 (default: the host architecture). Building for a
# foreign architecture needs qemu-user-static; CI builds natively instead.
# The bundle is written to OUTPUT_DIR (default: dist) as
# cz.zeropage.Reto-<ARCH>.flatpak.
set -euo pipefail

app_id=cz.zeropage.Reto
root=$(cd "$(dirname "$0")/.." && pwd)
arch=${1:-$(flatpak --default-arch)}
out=${2:-$root/dist}
work=$root/.flatpak

mkdir -p "$out"
flatpak-builder \
    --arch="$arch" \
    --user \
    --install-deps-from=flathub \
    --force-clean \
    --disable-rofiles-fuse \
    --state-dir="$work/state" \
    --repo="$work/repo-$arch" \
    "$work/build-$arch" \
    "$root/flatpak/$app_id.yaml"

flatpak build-bundle \
    --arch="$arch" \
    --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo \
    "$work/repo-$arch" \
    "$out/$app_id-$arch.flatpak" \
    "$app_id"

echo "Built $out/$app_id-$arch.flatpak"
