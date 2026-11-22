# Igual que /usr/bin/xpra, pero con el nombre de programa "ireport".
#
# En Wayland el cliente GTK de Xpra usa su nombre de programa (prgname) como app_id
# de las ventanas, y Xpra lo fija a "Xpra": el escritorio asocia entonces las
# ventanas de iReport a xpra.desktop y muestra el icono de Xpra. xpra.platform.set_name()
# solo tiene efecto la primera vez, así que llamándolo aquí antes de main() las
# ventanas quedan con app_id "ireport" y se asocian a ireport.desktop (icono y nombre).
#
# ireport-x11.sh lo usa vía XPRA_COMMAND, que es el comando con el que el servidor
# lanza su cliente ("... attach"). Se ejecuta con el mismo Python que /usr/bin/xpra.
import sys

from xpra.platform import init, set_default_name

set_default_name("Xpra")
init()
try:
    from xpra.platform import set_name
    set_name("ireport", "iReport")
except Exception:  # versiones de Xpra sin set_name: se queda con el icono de Xpra
    pass

from xpra.scripts.main import main

sys.exit(main(sys.argv[0], sys.argv))
