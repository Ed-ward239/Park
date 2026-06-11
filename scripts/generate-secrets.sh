#!/bin/bash
# Generates Park/Secrets.plist from .env so the app bundle gets the API key.
# Run after changing .env:  ./scripts/generate-secrets.sh
set -euo pipefail
cd "$(dirname "$0")/.."

source .env

cat > Park/Secrets.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>GEMINI_API_KEY</key>
	<string>${GEMINI_API_KEY}</string>
</dict>
</plist>
EOF

echo "Park/Secrets.plist generated from .env"
