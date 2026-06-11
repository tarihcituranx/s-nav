#!/bin/bash

# === OTOMATİK IP ALGILAMA ===
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || curl -s ipecho.net/plain)
DOMAIN="http://${SERVER_IP}"

# === AYARLAR ===
VIDEO_DIR="/var/www/videos"
M3U_OUTPUT="/var/www/videos/playlist.m3u8"

echo "🌐 Sunucu IP: $SERVER_IP"

# === VİDEO + ALTYAZI EŞLEŞMESİ ===
TITLES=(
  "Anten Dizisi - 1. Bölüm"
  "Anten Dizisi - 2. Bölüm"
  "Anten Dizisi - 3. Bölüm"
)

URLS=(
  "https://youtu.be/c7V9fg-Zryw"
  "https://youtu.be/-jvmyg0cgB0"
  "https://youtu.be/4ksYp3VSZiI"
)

SUBTITLES=(
  "https://cdn.jsdelivr.net/gh/tarihcituranx/s-nav@main/episode1_tr.vtt"
  "https://cdn.jsdelivr.net/gh/tarihcituranx/s-nav@main/episode2_tr.vtt"
  "https://cdn.jsdelivr.net/gh/tarihcituranx/s-nav@main/episode3_tr.vtt"
)

DURATIONS=(
  "2822"
  "3243"
  "2673"
)

LOGOS=(
  "https://i.ytimg.com/vi/c7V9fg-Zryw/mqdefault.jpg"
  "https://i.ytimg.com/vi/-jvmyg0cgB0/mqdefault.jpg"
  "https://i.ytimg.com/vi/4ksYp3VSZiI/mqdefault.jpg"
)

# === KLASÖR OLUŞTUR ===
echo "📁 Klasör oluşturuluyor..."
mkdir -p "$VIDEO_DIR"

# === NGİNX AYARLA ===
echo "⚙️  Nginx ayarlanıyor..."
cat > /etc/nginx/sites-available/videos <<EOF
server {
    listen 80;
    server_name _;

    location /videos/ {
        root /var/www;
        autoindex on;
        mp4;
        mp4_buffer_size 1m;
        mp4_max_buffer_size 5m;
        add_header Access-Control-Allow-Origin *;
    }
}
EOF

ln -sf /etc/nginx/sites-available/videos /etc/nginx/sites-enabled/videos
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# === M3U8 BAŞLAT ===
echo "#EXTM3U" > "$M3U_OUTPUT"
echo "#PLAYLIST:Anten Dizisi | سریال آنتن" >> "$M3U_OUTPUT"

# === VİDEOLARI İNDİR VE M3U8 OLUŞTUR ===
for i in "${!TITLES[@]}"; do
  TITLE="${TITLES[$i]}"
  URL="${URLS[$i]}"
  SUBTITLE="${SUBTITLES[$i]}"
  DURATION="${DURATIONS[$i]}"
  LOGO="${LOGOS[$i]}"
  FILENAME="bolum$((i+1)).mp4"
  FILEPATH="$VIDEO_DIR/$FILENAME"

  echo ""
  echo "⬇️  İndiriliyor [$((i+1))/${#TITLES[@]}]: $TITLE"

  if [ -f "$FILEPATH" ]; then
    echo "✅ Zaten mevcut, atlanıyor: $FILENAME"
  else
    yt-dlp -f "best[ext=mp4]/best" -o "$FILEPATH" "$URL"
    echo "✅ İndirildi: $FILENAME"
  fi

  # M3U8'e ekle
  echo "" >> "$M3U_OUTPUT"
  echo "#EXTINF:${DURATION} tvg-logo=\"${LOGO}\",${TITLE}" >> "$M3U_OUTPUT"
  echo "#EXTVLCOPT:sub-file=${SUBTITLE}" >> "$M3U_OUTPUT"
  echo "${DOMAIN}/videos/${FILENAME}" >> "$M3U_OUTPUT"
done

# === BİTİŞ ===
echo ""
echo "🎉 Her şey tamamlandı!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📄 M3U8 linkin:"
echo "   ${DOMAIN}/videos/playlist.m3u8"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
