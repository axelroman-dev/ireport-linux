#!/bin/bash
# Ejecuta iReport en su propio servidor X11 aislado mediante Xpra (modo seamless):
# cada ventana de iReport aparece como una ventana normal del escritorio Wayland.
# Requiere: xpra, Xvfb, xauth (y xdpyinfo + xrandr para ajustar la ventana); ver lib/distro.sh
# IREPORT_DEBUG=1 muestra el log de Xpra en la terminal.
# WIN_W / WIN_H: tamaño máximo de la ventana principal (por defecto 1920x1080).
# IREPORT_MONITOR: monitor donde abrir (nombre de "xrandr --listactivemonitors"; por defecto el principal).

APPDIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
USERDIR="$HOME/.ireport/5.6.0"
export WIN_W="${WIN_W:-1920}" WIN_H="${WIN_H:-1080}"

# Proceso hijo dentro de Xpra: ajustar la ventana al monitor y arrancar iReport desde el home
if [ "$1" = "--child" ]; then
    shift
    . "$APPDIR/lib/window.sh"
    fit_main_window "$USERDIR/config/Windows2Local/WindowManager.wswmgr"
    cd "$HOME" || exit 1
    exec "$APPDIR/bin/ireport" --jdkhome "$APPDIR/jre" "$@"
fi

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

# Display del escritorio (XWayland): el hijo lo usa para leer los monitores con xrandr
export IREPORT_HOST_DISPLAY="${DISPLAY:-}"

# Buscar un número de display libre
D=10
while [ -e "/tmp/.X11-unix/X$D" ] || [ -e "/tmp/.X$D-lock" ]; do D=$((D + 1)); done

LOG="$USERDIR/var/log/xpra.log"
mkdir -p "$(dirname "$LOG")"
[ -z "$IREPORT_DEBUG" ] && exec >"$LOG" 2>&1

# Opciones que solo existen desde Xpra 4 (Debian 12 y Ubuntu 24.04 traen la 3.1).
# --headerbar=no: sin la barra GTK de Xpra (icono, menú ☰); la barra la dibuja el escritorio.
XPRA_EXTRA=()
XPRA_MAJOR="$(xpra --version 2>/dev/null | sed -n 's/^xpra v\([0-9]*\).*/\1/p' | head -1)"
[ "${XPRA_MAJOR:-0}" -ge 4 ] && XPRA_EXTRA+=(--splash=no --headerbar=no)

# Cliente de Xpra con app_id "ireport" para que el escritorio muestre el icono de
# ireport.desktop (ver lib/xpra-ireport.py). Usa el mismo Python que /usr/bin/xpra.
XPRA_PY="$(sed -n '1s/^#! *\(.*python[^ ]*.*\)$/\1/p' "$(command -v xpra)" 2>/dev/null)"
if [ -n "$XPRA_PY" ] && $XPRA_PY -c 'from xpra.platform import set_name' 2>/dev/null; then
    read -ra XPRA_PY_ARR <<< "$XPRA_PY"
    export XPRA_COMMAND="$(printf '%q ' "${XPRA_PY_ARR[@]}" "$APPDIR/lib/xpra-ireport.py")"
fi

exec xpra start ":$D" \
    --start-child="$(printf '%q ' "$APPDIR/ireport-x11.sh" --child "$@")" \
    --xvfb="Xvfb +extension Composite +extension RANDR +extension RENDER -screen 0 5120x2880x24+32 -nolisten tcp -noreset -dpi 96" \
    --exit-with-children=yes \
    --title=@title@ \
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
