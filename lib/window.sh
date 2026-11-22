# Calcula la posición y el tamaño de la ventana principal de iReport para que quepa
# en un monitor del escritorio. Se carga con "." desde ireport-x11.sh (modo --child,
# dentro del Xvfb de Xpra).
#
# Xpra ajusta el Xvfb al tamaño de TODO el escritorio en píxeles lógicos de Wayland
# (p. ej. 3440x2720 con dos monitores), pero no expone cada monitor. Los monitores
# se leen del display del escritorio (XWayland, IREPORT_HOST_DISPLAY) con xrandr,
# que en KDE con escala fraccional los da multiplicados por la escala; se corrigen
# dividiendo entre (ancho de XWayland / ancho del Xvfb).
#
# Variables opcionales: WIN_W, WIN_H (tamaño máximo; por defecto 1920x1080),
# IREPORT_MONITOR (nombre del monitor, p. ej. HDMI-A-1; por defecto el principal).

# window_geometry: imprime "X Y ANCHO ALTO"
window_geometry() {
    local max_w="${WIN_W:-1920}" max_h="${WIN_H:-1080}" iw="" ih="" i

    # Esperar (máx. 5 s) a que Xpra ajuste el Xvfb al escritorio del cliente
    for i in $(seq 50); do
        read -r iw ih < <(xdpyinfo 2>/dev/null | awk '/dimensions:/ { split($2, d, "x"); print d[1], d[2] }')
        [ -n "$iw" ] && [ "$iw" != 5120 ] && break
        sleep 0.1
    done
    iw="${iw:-$max_w}"; ih="${ih:-$max_h}"

    local monitors=""
    if [ -n "${IREPORT_HOST_DISPLAY:-}" ] && command -v xrandr >/dev/null; then
        monitors="$(DISPLAY="$IREPORT_HOST_DISPLAY" xrandr --listactivemonitors 2>/dev/null)"
    fi

    # Línea de xrandr: " 0: +*eDP-1 2560/345x1600/215+744+1800  eDP-1"
    printf '%s\n' "$monitors" | awk -v iw="$iw" -v ih="$ih" -v mw="$max_w" -v mh="$max_h" \
        -v want="${IREPORT_MONITOR:-}" '
        $1 ~ /^[0-9]+:$/ {
            name = $2; primary = (name ~ /\*/); gsub(/[+*]/, "", name)
            split($3, g, /[x+]/); split(g[1], gw, "/"); split(g[2], gh, "/")
            n++; N[n] = name; P[n] = primary; W[n] = gw[1]; H[n] = gh[1]; X[n] = g[3]; Y[n] = g[4]
            if (X[n] + W[n] > hostw) hostw = X[n] + W[n]
        }
        END {
            sel = 0
            for (i = 1; i <= n; i++) if (want != "" && N[i] == want) sel = i
            if (!sel) for (i = 1; i <= n; i++) if (P[i]) sel = i
            if (!sel && n) sel = 1
            if (sel && hostw > 0) {
                f = hostw / iw
                x = X[sel] / f; y = Y[sel] / f; w = W[sel] / f; h = H[sel] / f
            } else { x = 0; y = 0; w = iw; h = ih }
            # Como máximo WIN_W x WIN_H y nunca más del 90% del monitor
            ww = (w * 0.9 < mw) ? w * 0.9 : mw
            wh = (h * 0.9 < mh) ? h * 0.9 : mh
            printf "%d %d %d %d\n", x + (w - ww) / 2, y + (h - wh) / 2, ww, wh
        }'
}

# fit_main_window ARCHIVO.wswmgr: aplica la geometría a la ventana principal
fit_main_window() {
    local wsmgr="$1" x y w h
    [ -f "$wsmgr" ] || return 0
    read -r x y w h < <(window_geometry)
    [ -n "$h" ] || return 0
    # Solo el primer bloque (joined-properties de main-window)
    sed -i "0,/^\/>/{
        s/^   x=\"[0-9-]*\"/   x=\"$x\"/
        s/^   y=\"[0-9-]*\"/   y=\"$y\"/
        s/^   width=\"[0-9]*\"/   width=\"$w\"/
        s/^   height=\"[0-9]*\"/   height=\"$h\"/
        s/^   frame-state=\"[0-9]*\"/   frame-state=\"0\"/
    }" "$wsmgr"
}
