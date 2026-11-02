#!/usr/bin/env bash
# Capturas para las tiendas en el simulador de iOS (ver "Capturas" en docs/store-listing.md).
#
#   tool/screenshots.sh                     # todas, en el simulador que esté abierto
#   tool/screenshots.sh jardin-noche matcha # solo esas
#   DEVICE="iPad Pro 13-inch (M5)" tool/screenshots.sh
#   PLAY=1 tool/screenshots.sh              # además, copias 1080×1920 (9:16) para Play
#   RESET=1 tool/screenshots.sh             # desinstala antes (jardín nuevo, con las tarjetas de primera vez)
#
# Cada captura compila con sus --dart-define (son de compilación), instala, abre, espera WAIT segundos
# (la puerta shoji y la entrada) y guarda en store/screenshots/<dispositivo>/, que no se commitea.
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${DEVICE:-booted}"
WAIT="${WAIT:-8}"
BUNDLE=com.oraki.sandora
APP=build/ios/iphonesimulator/Runner.app

# nombre|dart-defines. SANDORA_DAY=7 abre todos los minijuegos por días de juego.
SHOTS=(
  "jardin-dia|SANDORA_DAY=7 SANDORA_HOUR=10 SANDORA_WEATHER=clear"
  "jardin-noche|SANDORA_DAY=7 SANDORA_HOUR=22 SANDORA_WEATHER=clear"
  "jardin-lluvia|SANDORA_DAY=7 SANDORA_HOUR=16 SANDORA_WEATHER=rain"
  "jardin-nieve|SANDORA_DAY=7 SANDORA_HOUR=8 SANDORA_WEATHER=snow"
  "apilado|SANDORA_DAY=7 SANDORA_HOUR=10 SANDORA_GAME=stack"
  "arena|SANDORA_DAY=7 SANDORA_HOUR=10 SANDORA_GAME=sand"
  "lluvia|SANDORA_DAY=7 SANDORA_HOUR=16 SANDORA_WEATHER=rain SANDORA_GAME=rain"
  "matcha|SANDORA_DAY=7 SANDORA_HOUR=10 SANDORA_GAME=matcha"
  "enso|SANDORA_DAY=7 SANDORA_HOUR=10 SANDORA_GAME=enso"
  "linternas|SANDORA_DAY=7 SANDORA_HOUR=20 SANDORA_GAME=lanterns"
)

if [[ "$DEVICE" != booted ]]; then
  xcrun simctl boot "$DEVICE" 2>/dev/null || true
  open -a Simulator
  xcrun simctl bootstatus "$DEVICE" -b >/dev/null
fi
name=$(xcrun simctl list devices booted | sed -n 's/^ *\(.*\) ([0-9A-F-]*) (Booted).*/\1/p' | head -1)
[[ "$DEVICE" == booted ]] || name="$DEVICE"
[[ -n "$name" ]] || { echo "No hay ningún simulador abierto (o pasá DEVICE=...)." >&2; exit 1; }
OUT="store/screenshots/$(echo "$name" | tr ' ' '-' | tr -cd '[:alnum:]-')"
mkdir -p "$OUT"

# Barra de estado prolija: 9:41, batería llena, señal completa.
xcrun simctl status_bar "$DEVICE" override --time 9:41 --batteryState charged --batteryLevel 100 \
  --cellularBars 4 --wifiBars 3 --dataNetwork wifi

if [[ "${RESET:-0}" == 1 ]]; then
  xcrun simctl uninstall "$DEVICE" "$BUNDLE" || true
fi

for entry in "${SHOTS[@]}"; do
  shot="${entry%%|*}"
  defines="${entry#*|}"
  if [[ $# -gt 0 && ! " $* " =~ " $shot " ]]; then continue; fi

  echo "== $shot ($defines)"
  args=()
  for d in $defines; do args+=("--dart-define=$d"); done
  flutter build ios --simulator --debug "${args[@]}" >/dev/null

  xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
  xcrun simctl install "$DEVICE" "$APP"
  xcrun simctl launch "$DEVICE" "$BUNDLE" >/dev/null
  sleep "$WAIT"
  xcrun simctl io "$DEVICE" screenshot --type=png "$OUT/$shot.png" >/dev/null
  echo "   $OUT/$shot.png ($(sips -g pixelWidth -g pixelHeight "$OUT/$shot.png" | awk '/pixel/ {print $2}' | paste -sd x -))"

  # Play pide 9:16 para destacar capturas: recorte centrado (saca la barra de estado) y 1080×1920.
  # Solo en teléfonos (la captura es más alta que 9:16; en iPad no alcanza).
  w=$(sips -g pixelWidth "$OUT/$shot.png" | awk '/pixelWidth/ {print $2}')
  h=$(sips -g pixelHeight "$OUT/$shot.png" | awk '/pixelHeight/ {print $2}')
  if [[ "${PLAY:-0}" == 1 && $((w * 16 / 9)) -le $h ]]; then
    mkdir -p "$OUT/play"
    cp "$OUT/$shot.png" "$OUT/play/$shot.png"
    sips --cropToHeightWidth $((w * 16 / 9)) "$w" "$OUT/play/$shot.png" >/dev/null
    sips -z 1920 1080 "$OUT/play/$shot.png" >/dev/null
  fi
done

xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
xcrun simctl status_bar "$DEVICE" clear
echo "Listo: $OUT"
