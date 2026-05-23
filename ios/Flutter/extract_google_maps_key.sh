#!/bin/sh
# Extrae GOOGLE_MAPS_API_KEY de DART_DEFINES y la escribe en un plist del bundle.
set -e

API_KEY=""
GENERATED_XCCONFIG="${SRCROOT}/Flutter/Generated.xcconfig"
OUTPUT_PLIST="${SRCROOT}/Runner/GoogleMapsApiKey.plist"

if [ -f "$GENERATED_XCCONFIG" ]; then
  DART_DEFINES=$(grep '^DART_DEFINES=' "$GENERATED_XCCONFIG" | cut -d '=' -f2-)
  OLD_IFS=$IFS
  IFS=','
  for entry in $DART_DEFINES; do
    DECODED=$(printf '%s' "$entry" | base64 --decode 2>/dev/null || true)
    case "$DECODED" in
      GOOGLE_MAPS_API_KEY=*)
        API_KEY="${DECODED#GOOGLE_MAPS_API_KEY=}"
        ;;
    esac
  done
  IFS=$OLD_IFS
fi

cat > "$OUTPUT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>GMSApiKey</key>
  <string>${API_KEY}</string>
</dict>
</plist>
EOF
