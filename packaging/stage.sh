# Funciones comunes de build-appimage.sh y build-packages.sh (se carga con ".").
# Requiere REPO (raíz del repo) y BUILD (directorio de trabajo).

# stage_app DESTINO: archivos versionados de la aplicación + el JDK embebido
stage_app() {
    local dest="$1"
    [ -x "$REPO/jre/bin/java" ] || "$REPO/setup.sh"
    rm -rf "$dest"
    mkdir -p "$dest"
    (cd "$REPO" && git ls-files -z -- . ':!.gitignore' ':!README.md' ':!build-*.sh' ':!setup.sh' ':!packaging' \
        | xargs -0 cp --parents -t "$dest")
    cp -a "$REPO/jre" "$dest/"
}

# make_icon DESTINO.png: frame48_ireport.gif del branding de iReport, convertido con el propio JDK
make_icon() {
    mkdir -p "$BUILD"
    unzip -p "$REPO/ireport/core/locale/core_ireport.jar" org/netbeans/core/startup/frame48_ireport.gif > "$BUILD/icon.gif"
    cat > "$BUILD/Gif2Png.java" <<'JAVA'
public class Gif2Png {
    public static void main(String[] a) throws Exception {
        javax.imageio.ImageIO.write(javax.imageio.ImageIO.read(new java.io.File(a[0])), "png", new java.io.File(a[1]));
    }
}
JAVA
    "$REPO/jre/bin/javac" -d "$BUILD" "$BUILD/Gif2Png.java"
    mkdir -p "$(dirname "$1")"
    "$REPO/jre/bin/java" -cp "$BUILD" Gif2Png "$BUILD/icon.gif" "$1"
}

# write_desktop DESTINO EXEC
write_desktop() {
    mkdir -p "$(dirname "$1")"
    cat > "$1" <<DESKTOP
[Desktop Entry]
Type=Application
Name=iReport 5.6.0
Comment=Diseñador de reportes JasperReports
Exec=$2
Icon=ireport
Categories=Development;Office;
Terminal=false
DESKTOP
}
