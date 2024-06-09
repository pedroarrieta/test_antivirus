#!/bin/bash

# Archivo de firmas de malware
SIGNATURES_FILE="signatures.txt"
LOG_FILE="scan_log.txt"
QUARANTINE_DIR="$HOME/quarantine"
SCAN_DIR="$HOME"

# Función para mostrar el uso del script
usage() {
    echo "Usage: $0 [-d directory] [-s signatures] [-l log] [-q quarantine]"
    exit 1
}

# Procesar opciones de línea de comandos
while getopts "d:s:l:q:" opt; do
    case $opt in
        d) SCAN_DIR=$OPTARG ;;
        s) SIGNATURES_FILE=$OPTARG ;;
        l) LOG_FILE=$OPTARG ;;
        q) QUARANTINE_DIR=$OPTARG ;;
        *) usage ;;
    esac
done

# Crear directorio de cuarentena si no existe
mkdir -p "$QUARANTINE_DIR"

# Función para escanear archivos
scan_file() {
    local file=$1
    while IFS= read -r signature; do
        if grep -q "$signature" "$file"; then
            echo "[ALERTA] Se encontró una posible infección en $file"
            echo "Firma detectada: $signature"
            echo "$(date): $file - $signature" >> "$LOG_FILE"
            # Mover archivo a cuarentena
            mv "$file" "$QUARANTINE_DIR"
            echo "Archivo movido a cuarentena: $QUARANTINE_DIR/$(basename "$file")"
        fi
    done < "$SIGNATURES_FILE"
}

# Escanear directorios recursivamente
scan_directory() {
    local dir=$1
    for item in "$dir"/*; do
        if [ -d "$item" ]; then
            scan_directory "$item"
        elif [ -f "$item" ]; then
            scan_file "$item"
        fi
    done
}

# Comprobar si el archivo de firmas existe
if [ ! -f "$SIGNATURES_FILE" ]; then
    echo "El archivo de firmas $SIGNATURES_FILE no se encuentra."
    exit 1
fi

# Iniciar el escaneo
echo "Iniciando el escaneo en $SCAN_DIR..."
scan_directory "$SCAN_DIR"
echo "Escaneo completado. Resultados registrados en $LOG_FILE."
