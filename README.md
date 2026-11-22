# iReport 5.6.0 para Linux (Wayland)

iReport 5.6.0 (Jaspersoft, 2014) adaptado para correr en un Linux moderno con sesión **Wayland**, sin instalar Java viejo en el sistema ni cambiar a una sesión X11.

Un solo repo para las tres familias de distros: **Arch/CachyOS**, **Fedora** y **Debian/Ubuntu** (más openSUSE, sin probar). Los scripts detectan la distro (`/etc/os-release`) y piden los paquetes correctos, y hay paquetes nativos `.pkg.tar.zst`, `.rpm` y `.deb`. Unifica [ireport-5.6.0-cachyos](https://github.com/axelroman-dev/ireport-5.6.0-cachyos) y su variante para Fedora.

> **Proyecto no oficial.** No está afiliado ni respaldado por Jaspersoft / TIBCO / Cloud Software Group. "iReport" y "JasperReports" son marcas de sus respectivos dueños. iReport está descontinuado; su sucesor oficial es Jaspersoft Studio.

> **Seguridad.** Java 7 e iReport 5.6.0 ya no reciben parches de seguridad. Úsalo para diseñar reportes en tu equipo; no abras `.jrxml`/`.jasper` de origen desconocido ni lo expongas a la red.

## Instalación con paquete nativo (recomendado)

Descarga el paquete de tu distro desde [Releases](https://github.com/axelroman-dev/ireport-linux/releases). El gestor de paquetes instala las dependencias (Xpra, Xvfb, xauth) y deja el comando `ireport` y el acceso en el menú. Se instala en `/opt/ireport-5.6.0`.

| Distro | Paquete | Instalar |
|---|---|---|
| Arch, CachyOS, Manjaro, EndeavourOS | `ireport-5.6.0-1-x86_64.pkg.tar.zst` | `sudo pacman -U ireport-5.6.0-1-x86_64.pkg.tar.zst` |
| Fedora, RHEL/Rocky/Alma (con EPEL), openSUSE | `ireport-5.6.0-1.x86_64.rpm` | `sudo dnf install ./ireport-5.6.0-1.x86_64.rpm` |
| Debian, Ubuntu, Linux Mint, Pop!_OS | `ireport_5.6.0-1_amd64.deb` | `sudo apt install ./ireport_5.6.0-1_amd64.deb` |

Desinstalar: `sudo pacman -R ireport` / `sudo dnf remove ireport` / `sudo apt remove ireport`.

## Uso desde el repo (sin instalar)

```bash
./setup.sh          # descarga el JDK 7 en ./jre y te dice qué paquetes instalar en tu distro
./ireport-x11.sh    # abre iReport
```

Dependencias según la distro (lo mismo que imprime `setup.sh`, definido en `lib/distro.sh`):

| Familia | Comando |
|---|---|
| Arch / CachyOS | `sudo pacman -S --needed xpra xorg-server-xvfb xorg-xauth xorg-xdpyinfo` |
| Fedora | `sudo dnf install xpra xorg-x11-server-Xvfb xorg-x11-xauth xdpyinfo` |
| Debian / Ubuntu | `sudo apt install xpra xvfb xauth x11-utils` |
| openSUSE | `sudo zypper install xpra xorg-x11-server-Xvfb xauth xdpyinfo` |

## AppImage

Un solo archivo con iReport + JDK 7 + lanzador, para cualquier distro. El sistema solo necesita las dependencias de la tabla anterior.

```bash
curl -LO https://github.com/axelroman-dev/ireport-linux/releases/latest/download/iReport-5.6.0-x86_64.AppImage
curl -LO https://github.com/axelroman-dev/ireport-linux/releases/latest/download/iReport-5.6.0-x86_64.AppImage.sha256
sha256sum -c iReport-5.6.0-x86_64.AppImage.sha256
chmod +x iReport-5.6.0-x86_64.AppImage
./iReport-5.6.0-x86_64.AppImage
```

## Construir los paquetes

Todo se genera desde cualquier distro (no hace falta `dpkg`, `rpmbuild` ni `makepkg`): `build-packages.sh` descarga [nfpm](https://nfpm.goreleaser.com) (versión fija, verificada con SHA-256) y genera los tres paquetes desde `packaging/nfpm.yaml`. `build/` y `dist/` no se versionan.

```bash
./build-packages.sh              # .deb + .rpm + .pkg.tar.zst en dist/
./build-packages.sh rpm          # solo uno (deb | rpm | archlinux)
RELEASE=2 ./build-packages.sh    # revisión del paquete (5.6.0-2)
./build-appimage.sh              # dist/iReport-5.6.0-x86_64.AppImage
```

Publicar una versión nueva:

```bash
cd dist && sha256sum iReport-5.6.0-x86_64.AppImage *.deb *.rpm *.pkg.tar.zst > SHA256SUMS && cd ..
gh release create v5.6.0-N dist/* --title "iReport 5.6.0 (build N)" --notes "..."
```

Cada Release debe incluir también `iReport-5.6.0-src.zip` (código fuente de iReport, requisito de la AGPL; ver [Licencias](#licencias)).

## Problemas y soluciones

| Problema | Causa | Solución |
|---|---|---|
| No arranca con el Java del sistema | iReport (NetBeans 6.5) solo funciona con **Java 7** | JDK 7 propio en `jre/` (Azul Zulu 7u352), descargado por `setup.sh` con verificación SHA-256. `etc/ireport.conf` usa `jdkhome="jre"` |
| Ventana en blanco en Wayland (también pasaba en Kubuntu Wayland) | Java 7 + XWayland | Se ejecuta en un **servidor X11 propio y aislado** con **Xpra** en modo *seamless*: cada ventana de iReport aparece como ventana normal de KDE (redimensionable, maximizable) |
| Cuelgue/NPE al iniciar con un diálogo vacío | El módulo `heartbeat` busca actualizaciones en `ireport.sf.net` (ya no existe) y su diálogo falla | Módulo desactivado en `ireport/config/Modules/com-jaspersoft-ireport-heartbeat.xml` |
| Driver MySQL | Los conectores 8.x requieren Java 8+ | `setup.sh` copia `libs/mysql-connector-java-5.1.49.jar` a `jre/jre/lib/ext/` (siempre en el classpath, sin configurarlo en iReport). Funciona con MySQL 5.x y 8.0. Clase: `com.mysql.jdbc.Driver` |

Se probó y descartó **Xephyr + Openbox** (X11 anidado en una ventana): funciona, pero al redimensionar la ventana no se ajusta la pantalla interna (recorta o deja bordes negros).

## Archivos propios de este repo

- `setup.sh` — descarga/verifica el JDK 7 y coloca el driver MySQL.
- `lib/distro.sh` — detecta la familia de distro y define el comando de instalación de dependencias.
- `build-packages.sh` + `packaging/nfpm.yaml` — paquetes `.deb`, `.rpm` y Arch con nfpm.
- `build-appimage.sh` — arma el AppDir y lo empaqueta con `appimagetool`.
- `packaging/stage.sh` — funciones comunes a ambos: copia los archivos versionados + `jre/`, genera el `.desktop` y el icono (extraído de `core_ireport.jar`).
- `ireport-x11.sh` — lanzador:
  - busca un display libre y arranca `xpra` con `Xvfb` (5120x2880 virtual) y iReport como proceso hijo; todo se cierra al cerrar iReport;
  - abre la ventana principal en **1920x1080 centrada** (ajusta `~/.ireport/5.6.0/config/Windows2Local/WindowManager.wswmgr`); se cambia con `WIN_W`/`WIN_H` en el script;
  - arranca iReport desde `$HOME` y con `--jdkhome` absoluto a `jre/`;
  - el log de Xpra va a `~/.ireport/5.6.0/var/log/xpra.log`; para verlo en la terminal: `IREPORT_DEBUG=1 ./ireport-x11.sh`.
- `etc/ireport.conf` — `jdkhome="jre"`, `-Xmx1024m`, suavizado de fuentes.

## Datos útiles

- Configuración del usuario y logs de iReport: `~/.ireport/5.6.0/` (`var/log/messages.log`).
- Si cambias módulos o algo no se aplica, borra la caché: `rm -rf ~/.ireport/5.6.0/var/cache`.
- Si los paneles quedan desordenados: *Window → Reset Windows*.
- En Debian/Ubuntu el `xpra` de los repos puede ser antiguo; si falla al arrancar, usa el repo oficial de [xpra.org](https://github.com/Xpra-org/xpra/wiki/Download).
- Los avisos de `xkbcomp`, `dbus`, `pulseaudio`, `vp9` y `fgrep` en el log son normales.
- Portapapeles entre iReport y otras apps: lo sincroniza Xpra.
- Los nombres de los paquetes cambian entre distros (p. ej. `xorg-server-xvfb` en Arch, `xorg-x11-server-Xvfb` en Fedora, `xvfb` en Debian); están todos en `lib/distro.sh` y `packaging/nfpm.yaml`.
- El AppImage necesita FUSE 2 (`fuse2` en Arch, `fuse-libs` en Fedora, `libfuse2t64`/`libfuse2` en Ubuntu/Debian). Si no lo tienes, ejecútalo con `./iReport-5.6.0-x86_64.AppImage --appimage-extract-and-run`.

## Pendiente

- Probar en una sesión real de Debian/Ubuntu y openSUSE.

## Créditos

- **Axel Román** ([@axelroman-dev](https://github.com/axelroman-dev)): idea, requisitos y pruebas en CachyOS/KDE Wayland y Fedora 45 KDE Wayland.
- **Claude** (Anthropic, vía Claude Code): diagnóstico, scripts, empaquetado (AppImage, .deb, .rpm, Arch) y documentación.

## Licencias

| Componente | Licencia | Código fuente |
|---|---|---|
| Scripts y documentación de este repo (`README.md`, `setup.sh`, `ireport-x11.sh`, `lib/`, `packaging/`, `build-*.sh`) | MIT — ver `LICENSE-scripts` | este repo |
| iReport 5.6.0 (sin modificar salvo `etc/ireport.conf` y la desactivación del módulo heartbeat) | AGPLv3 — `LICENSE_ireport.txt`, `notice.txt` | `iReport-5.6.0-src.zip` adjunto en cada [Release](https://github.com/axelroman-dev/ireport-linux/releases); original en [SourceForge](https://sourceforge.net/projects/ireport/files/iReport/iReport-5.6.0/) |
| Bibliotecas incluidas en iReport (NetBeans, JasperReports, etc.) | Varias — `Third-Party-Notices.pdf`, `license-text-files/` | incluidas en el zip de fuentes / proyectos originales |
| MySQL Connector/J (`libs/`) | GPLv2 con Universal FOSS Exception | [mysql/mysql-connector-j](https://github.com/mysql/mysql-connector-j) (tags `5.1.49`, `8.0.33`, `8.3.0`) |
| Azul Zulu JDK 7u352 (no está en el repo; va dentro del AppImage y de los paquetes) | GPLv2 con Classpath Exception — `jre/LICENSE`, `jre/THIRD_PARTY_README` | `jre/src.zip` (biblioteca de clases) y oferta escrita de Azul en `jre/readme.txt` (azul_openjdk@azul.com); basado en [OpenJDK 7u](https://github.com/openjdk/jdk7u) |

Los cambios hechos sobre iReport están en el historial de git: `git diff 276445c d947782`.
