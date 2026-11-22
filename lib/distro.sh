# Detecta la distribución (/etc/os-release) y define el comando para instalar
# las dependencias del lanzador: Xpra, Xvfb, xauth y xdpyinfo.
# Uso: . lib/distro.sh; echo "$DISTRO_FAMILY"; echo "$DEPS_INSTALL"

DISTRO_FAMILY=unknown
if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    _ids="$(. /etc/os-release; echo "${ID:-} ${ID_LIKE:-}")"
    for _id in $_ids; do
        case "$_id" in
            arch|cachyos|manjaro|endeavouros) DISTRO_FAMILY=arch; break ;;
            fedora|rhel|centos|rocky|almalinux|nobara) DISTRO_FAMILY=fedora; break ;;
            debian|ubuntu|linuxmint|pop|elementary|zorin) DISTRO_FAMILY=debian; break ;;
            opensuse*|suse|sles) DISTRO_FAMILY=suse; break ;;
        esac
    done
    unset _ids _id
fi

case "$DISTRO_FAMILY" in
    arch)   DEPS_INSTALL="sudo pacman -S --needed xpra xorg-server-xvfb xorg-xauth xorg-xdpyinfo" ;;
    fedora) DEPS_INSTALL="sudo dnf install xpra xorg-x11-server-Xvfb xorg-x11-xauth xdpyinfo" ;;
    debian) DEPS_INSTALL="sudo apt install xpra xvfb xauth x11-utils" ;;
    suse)   DEPS_INSTALL="sudo zypper install xpra xorg-x11-server-Xvfb xauth xdpyinfo" ;;
    *)      DEPS_INSTALL="instala con el gestor de paquetes de tu distro: xpra, Xvfb, xauth, xdpyinfo" ;;
esac
