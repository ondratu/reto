#!/usr/bin/env bash
# Turn Flatpak bundles into a signed Flatpak repository that can be served
# from a static web server (GitHub Pages).
#
# Usage: tools/publish-flatpak-repo.sh BUNDLE_DIR SITE_DIR KEY_ID
#
# Imports every *.flatpak in BUNDLE_DIR into SITE_DIR/repo, signs it with the
# GPG key KEY_ID and writes reto.flatpakrepo and cz.zeropage.Reto.flatpakref
# next to it. The key is looked up in $GNUPGHOME (default: ~/.gnupg). The
# repository is rebuilt from the bundles on every run, so SITE_DIR should be
# empty or contain only the previous output.
#
# FLATPAK_BASE_URL is the public address of SITE_DIR
# (default: https://reto.zeropage.cz/flatpak).
set -euo pipefail

app_id=cz.zeropage.Reto
bundles=${1:?usage: $0 BUNDLE_DIR SITE_DIR KEY_ID}
site=${2:?usage: $0 BUNDLE_DIR SITE_DIR KEY_ID}
key=${3:?usage: $0 BUNDLE_DIR SITE_DIR KEY_ID}
base_url=${FLATPAK_BASE_URL:-https://reto.zeropage.cz/flatpak}
gnupg=${GNUPGHOME:-$HOME/.gnupg}
runtime_repo=https://dl.flathub.org/repo/flathub.flatpakrepo

repo=$site/repo
rm -rf "$repo"
mkdir -p "$site"
ostree init --mode=archive-z2 --repo="$repo"

shopt -s nullglob
files=("$bundles"/*.flatpak)
if [ ${#files[@]} -eq 0 ]; then
    echo "No .flatpak bundles in $bundles" >&2
    exit 1
fi
for bundle in "${files[@]}"; do
    flatpak build-import-bundle \
        --update-appstream \
        --gpg-sign="$key" --gpg-homedir="$gnupg" \
        "$repo" "$bundle"
done

flatpak build-update-repo \
    --title=Reto \
    --gpg-sign="$key" --gpg-homedir="$gnupg" \
    "$repo"

gpg_key=$(gpg --homedir "$gnupg" --export "$key" | base64 -w0)

cat > "$site/reto.flatpakrepo" <<REPO
[Flatpak Repo]
Title=Reto
Url=$base_url/repo/
Homepage=https://reto.zeropage.cz/
Comment=Reto, a CSV file viewer for GNOME
GPGKey=$gpg_key
REPO

cat > "$site/$app_id.flatpakref" <<REF
[Flatpak Ref]
Title=Reto
Name=$app_id
Branch=master
Url=$base_url/repo/
SuggestRemoteName=reto
IsRuntime=false
RuntimeRepo=$runtime_repo
GPGKey=$gpg_key
REF

echo "Published the repository to $site"
