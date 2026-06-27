#!/usr/bin/env bash
# Spotify waybar module — polls currently playing track via Spotify Web API.
# Credentials: ~/.config/waybar/spotify_credentials (not versioned)

CREDENTIALS_FILE="$HOME/.config/waybar/spotify_credentials"
TOKEN_CACHE="/tmp/spotify_waybar_token"

get_access_token() {
    local client_id client_secret refresh_token
    # shellcheck source=/dev/null
    source "$CREDENTIALS_FILE" 2>/dev/null || { echo ""; return; }
    client_id="$SPOTIFY_CLIENT_ID"
    client_secret="$SPOTIFY_CLIENT_SECRET"
    refresh_token="$SPOTIFY_REFRESH_TOKEN"

    if [[ -f "$TOKEN_CACHE" ]]; then
        local expiry cached_token now
        expiry=$(head -1 "$TOKEN_CACHE")
        cached_token=$(tail -1 "$TOKEN_CACHE")
        now=$(date +%s)
        if [[ $now -lt $expiry && -n "$cached_token" ]]; then
            echo "$cached_token"
            return
        fi
    fi

    local response access_token expires_in
    response=$(curl -s -X POST "https://accounts.spotify.com/api/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=refresh_token&refresh_token=${refresh_token}&client_id=${client_id}&client_secret=${client_secret}")

    access_token=$(echo "$response" | jq -r '.access_token // empty')
    expires_in=$(echo "$response" | jq -r '.expires_in // 0')

    if [[ -n "$access_token" ]]; then
        printf '%s\n%s\n' "$(( $(date +%s) + expires_in - 60 ))" "$access_token" > "$TOKEN_CACHE"
    fi

    echo "$access_token"
}

truncate_str() {
    local str="$1" max="$2"
    if [[ ${#str} -gt $max ]]; then
        printf '%s…' "${str:0:$((max - 1))}"
    else
        printf '%s' "$str"
    fi
}

output_json() {
    jq -cn --arg text "$1" --arg tooltip "$2" --arg class "$3" \
        '{"text": $text, "tooltip": $tooltip, "class": $class}'
}

while true; do
    token=$(get_access_token)

    if [[ -z "$token" ]]; then
        output_json " No credentials" "Configure ~/.config/waybar/spotify_credentials" "stopped"
        sleep 5
        continue
    fi

    response=$(curl -s \
        -H "Authorization: Bearer $token" \
        "https://api.spotify.com/v1/me/player/currently-playing")

    if [[ -z "$response" || "$response" == "null" ]]; then
        output_json " —" "Spotify not playing" "stopped"
        sleep 5
        continue
    fi

    is_playing=$(echo "$response" | jq -r '.is_playing // false')
    track=$(echo "$response" | jq -r '.item.name // "Unknown"')
    artist=$(echo "$response" | jq -r '[.item.artists[].name] | join(", ")')
    album=$(echo "$response" | jq -r '.item.album.name // ""')

    track_t=$(truncate_str "$track" 28)
    artist_t=$(truncate_str "$artist" 20)

    tooltip="$(printf '%s\n%s\n%s' "$track" "$artist" "$album")"

    if [[ "$is_playing" == "true" ]]; then
        text="  ${track_t} — ${artist_t}"
        class="playing"
    else
        text="  ${track_t} — ${artist_t}"
        class="paused"
    fi

    output_json "$text" "$tooltip" "$class"
    sleep 3
done
