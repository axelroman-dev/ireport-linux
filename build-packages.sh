#!/bin/bash
# Genera los paquetes nativos en dist/: .deb (Debian/Ubuntu), .rpm (Fedora/openSUSE)
# y .pkg.tar.zst (Arch/CachyOS) con nfpm. Se puede ejecutar en cualquier distro.
# Uso: ./build-packages.sh [deb|rpm|archlinux ...]   (sin argumentos: los tres)
#      RELEASE=2 ./build-packages.sh                 (número de revisión del paquete)
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
BUILD="$REPO/build"
DIST="$REPO/dist"
NFPM_VERSION="2.48.0"
NFPM_SHA256="6d7f9a28b2f397934403950fcbba83f598b08d02edbe79a0815b3b4897341750"
NFPM="$BUILD/nfpm-$NFPM_VERSION/nfpm"
. "$REPO/packaging/stage.sh"

export STAGE="$BUILD/pkgroot"
export RELEASE="${RELEASE:-1}"
FORMATS=("$@")
[ ${#FORMATS[@]} -eq 0 ] && FORMATS=(deb rpm archlinux)

if [ ! -x "$NFPM" ]; then
    mkdir -p "$(dirname "$NFPM")"
    TGZ="$BUILD/nfpm.tar.gz"
    curl -fL --progress-bar -o "$TGZ" \
        "https://github.com/goreleaser/nfpm/releases/download/v$NFPM_VERSION/nfpm_${NFPM_VERSION}_Linux_x86_64.tar.gz"
    echo "$NFPM_SHA256  $TGZ" | sha256sum -c -
    tar xzf "$TGZ" -C "$(dirname "$NFPM")" nfpm
    rm -f "$TGZ"
fi

stage_app "$STAGE/app"
write_desktop "$STAGE/ireport.desktop" ireport
make_icon "$STAGE/ireport.png"

mkdir -p "$DIST"
for f in "${FORMATS[@]}"; do
    "$NFPM" package --config "$REPO/packaging/nfpm.yaml" --packager "$f" --target "$DIST/"
done
ls -lh "$DIST"
