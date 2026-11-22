#!/bin/bash
# Ejecuta iReport en su propio servidor X11 aislado mediante Xpra (modo seamless):
# cada ventana de iReport aparece como una ventana normal del escritorio Wayland.
# Requiere: xpra, Xvfb, xauth (y xdpyinfo para centrar la ventana); ver lib/distro.sh
# IREPORT_DEBUG=1 muestra el log de Xpra en la terminal.

APPDIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# Proceso hijo dentro de Xpra: arrancar iReport desde el home del usuario
if [ "$1" = "--child" ]; then
    shift
    cd "$HOME" || exit 1
    exec "$APPDIR/bin/ireport" --jdkhome "$APPDIR/jre" "$@"
fi
USERDIR="$HOME/.ireport/5.6.0"
WIN_W=1920
WIN_H=1080

. "$APPDIR/lib/distro.sh"
for cmd in xpra Xvfb xauth; do
    if ! command -v "$cmd" >/dev/null; then
        MSG="Falta '$cmd'. Instálalo con: $DEPS_INSTALL"
        echo "$MSG" >&2
        # Lanzado desde el menú (sin terminal): avisar con una notificación
        [ -t 2 ] || notify-send -a iReport "iReport no puede arrancar" "$MSG" 2>/dev/null
        exit 1
    fi
done

# Tamaño inicial de la ventana principal: 1920x1080 centrada
WSMGR="$USERDIR/config/Windows2Local/WindowManager.wswmgr"
if [ -f "$WSMGR" ]; then
    read -r SW SH < <(xdpyinfo 2>/dev/null | awk '/dimensions:/ { split($2, d, "x"); print d[1], d[2] }')
    X=$(( (${SW:-$WIN_W} - WIN_W) / 2 )); [ $X -lt 0 ] && X=0
    Y=$(( (${SH:-$WIN_H} - WIN_H) / 2 )); [ $Y -lt 0 ] && Y=0
    # Solo el primer bloque (joined-properties de main-window)
    sed -i "0,/^\/>/{
        s/^   x=\"[0-9-]*\"/   x=\"$X\"/
        s/^   y=\"[0-9-]*\"/   y=\"$Y\"/
        s/^   width=\"[0-9]*\"/   width=\"$WIN_W\"/
        s/^   height=\"[0-9]*\"/   height=\"$WIN_H\"/
        s/^   frame-state=\"[0-9]*\"/   frame-state=\"0\"/
    }" "$WSMGR"
fi

# Buscar un número de display libre
D=10
while [ -e "/tmp/.X11-unix/X$D" ] || [ -e "/tmp/.X$D-lock" ]; do D=$((D + 1)); done

LOG="$USERDIR/var/log/xpra.log"
mkdir -p "$(dirname "$LOG")"
[ -z "$IREPORT_DEBUG" ] && exec >"$LOG" 2>&1

# --splash solo existe desde Xpra 4 (Debian 12 y Ubuntu 24.04 traen la 3.1)
XPRA_EXTRA=()
XPRA_MAJOR="$(xpra --version 2>/dev/null | sed -n 's/^xpra v\([0-9]*\).*/\1/p' | head -1)"
[ "${XPRA_MAJOR:-0}" -ge 4 ] && XPRA_EXTRA+=(--splash=no)

exec xpra start ":$D" \
    --start-child="$(printf '%q ' "$APPDIR/ireport-x11.sh" --child "$@")" \
    --xvfb="Xvfb +extension Composite +extension RANDR +extension RENDER -screen 0 5120x2880x24+32 -nolisten tcp -noreset -dpi 96" \
    --exit-with-children=yes \
    --ssh-upgrade=no \
    --attach=yes \
    --daemon=no \
    --tray=no \
    --notifications=no \
    --mdns=no \
    --html=off \
    --webcam=no \
    --speaker=no \
    --microphone=no \
    --printing=no \
    --systemd-run=no \
    "${XPRA_EXTRA[@]}"
