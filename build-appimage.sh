#!/bin/bash
# Construye dist/iReport-5.6.0-x86_64.AppImage con iReport, el JDK 7 embebido y el lanzador Xpra.
# En el sistema donde se ejecute el AppImage hacen falta Xpra, Xvfb y xauth (ver lib/distro.sh).
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
BUILD="$REPO/build"
APPDIR="$BUILD/iReport.AppDir"
OUT="$REPO/dist/iReport-5.6.0-x86_64.AppImage"
TOOL="$BUILD/appimagetool-x86_64.AppImage"
TOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
. "$REPO/packaging/stage.sh"

rm -rf "$APPDIR"
mkdir -p "$(dirname "$OUT")"
stage_app "$APPDIR/app"

cat > "$APPDIR/AppRun" <<'APPRUN'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/app/ireport-x11.sh" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"
write_desktop "$APPDIR/ireport.desktop" ireport
make_icon "$APPDIR/ireport.png"
ln -sf ireport.png "$APPDIR/.DirIcon"

if [ ! -x "$TOOL" ]; then
    curl -fL --progress-bar -o "$TOOL" "$TOOL_URL"
    chmod +x "$TOOL"
fi

rm -f "$OUT"
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$TOOL" --no-appstream "$APPDIR" "$OUT"
ls -lh "$OUT"
