#!/usr/bin/env bash
# One-time Spotify OAuth helper to obtain a refresh token.
# Run: bash ~/.config/waybar/scripts/spotify_auth.sh
# Then paste the values into ~/.config/waybar/spotify_credentials

CREDENTIALS_FILE="$HOME/.config/waybar/spotify_credentials"

echo "=== Spotify OAuth — obtention du refresh token ==="
echo ""
read -rp "Client ID     : " CLIENT_ID
read -rp "Client Secret : " CLIENT_SECRET
echo ""

REDIRECT_URI="http://127.0.0.1:8888/callback"
SCOPE="user-read-currently-playing"
AUTH_URL="https://accounts.spotify.com/authorize?client_id=${CLIENT_ID}&response_type=code&redirect_uri=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${REDIRECT_URI}'))")&scope=${SCOPE}"

echo "1. Ouvre cette URL dans ton navigateur :"
echo ""
echo "   $AUTH_URL"
echo ""
echo "2. Autorise l'accès, puis copie l'URL de redirection complète (commence par http://127.0.0.1:8888/callback?code=...)"
echo ""
read -rp "URL de redirection : " REDIRECT_URL

AUTH_CODE=$(echo "$REDIRECT_URL" | grep -oP '(?<=code=)[^&]+')

if [[ -z "$AUTH_CODE" ]]; then
    echo "Erreur : impossible d'extraire le code depuis l'URL."
    exit 1
fi

echo ""
echo "Échange du code contre un refresh token..."

RESPONSE=$(curl -s -X POST "https://accounts.spotify.com/api/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=authorization_code&code=${AUTH_CODE}&redirect_uri=${REDIRECT_URI}&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}")

REFRESH_TOKEN=$(echo "$RESPONSE" | jq -r '.refresh_token // empty')

if [[ -z "$REFRESH_TOKEN" ]]; then
    echo "Erreur : $(echo "$RESPONSE" | jq -r '.error_description // .error // "Réponse inattendue"')"
    exit 1
fi

echo ""
echo "Écriture des credentials dans $CREDENTIALS_FILE ..."

cat > "$CREDENTIALS_FILE" << EOF
SPOTIFY_CLIENT_ID="${CLIENT_ID}"
SPOTIFY_CLIENT_SECRET="${CLIENT_SECRET}"
SPOTIFY_REFRESH_TOKEN="${REFRESH_TOKEN}"
EOF

chmod 600 "$CREDENTIALS_FILE"
echo "Terminé ! Lance 'waybar' ou recharge ta session pour activer le module."
