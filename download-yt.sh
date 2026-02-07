#!/bin/bash

# Wrapper around termux-dialog that exits on cancel and returns the text value.
# Usage: result=$(tdialog [termux-dialog args...]) || exit 1
tdialog() {
  local data
  data=$(termux-dialog "$@")
  if [[ $(jq -r '.code' <<<"$data") -eq -2 ]]; then
    echo "User cancelled." >&2
    return 1
  fi
  jq -r '.text' <<<"$data"
}

echo "yt-dlp termux script"
cd ~/storage/shared/Music
archives_dir="/data/data/com.termux/files/home/archives"
mkdir -p "$archives_dir"
saved_playlists="${archives_dir}/savedPlaylists.txt"
touch "$saved_playlists"

# Build playlist choices from saved file
# Format of savedPlaylists.txt: one line per playlist, "name|url"
choices=()
urls=()
while IFS='|' read -r name link; do
  [[ -z "$name" ]] && continue
  choices+=("$name")
  urls+=("$link")
done < "$saved_playlists"
choices+=("+ New Playlist")

# Build comma-separated values string for termux-dialog
values=""
for c in "${choices[@]}"; do
  [[ -n "$values" ]] && values+=","
  values+="$c"
done

selected=$(tdialog spinner -t "Select a playlist" -v "$values") || exit 1

if [[ "$selected" == "+ New Playlist" ]]; then
  url=$(tdialog -t "Enter Youtube Playlist URL") || exit 1

  # Fetch playlist title automatically
  echo "Fetching playlist title..."
  playlist_name=$(python ~/yt-dlp --flat-playlist --playlist-items 1 --print "%(playlist_title)s" "$url" 2>/dev/null | head -1)
  [[ -z "$playlist_name" ]] && playlist_name="$url"

  # Save to file
  echo "${playlist_name}|${url}" >> "$saved_playlists"
  echo "Saved playlist: $playlist_name"
else
  # Find the URL and name for the selected playlist
  for i in "${!choices[@]}"; do
    if [[ "${choices[$i]}" == "$selected" ]]; then
      playlist_name="${choices[$i]}"
      url="${urls[$i]}"
      break
    fi
  done
fi

playlist_id=$(echo "$url" | grep -oP '(?<=list=)[^&]+')
archive_path="${archives_dir}/${playlist_id}_archive.txt"

# Clear the archive?
text=$(tdialog checkbox -t "Redownload full playlist?" -v "Redownload") || exit 1

if [[ "$text" == "[Redownload]" ]]; then
  echo "Removing $archive_path"
  rm -f "$archive_path"
fi

echo "Downloading playlist with URL: $url"
python ~/yt-dlp -x \
  --audio-format mp3 \
  --embed-thumbnail \
  --convert-thumbnails png \
  --ppa "EmbedThumbnail+ffmpeg_o:-c:v png -vf crop=\"'if(gt(ih,iw),iw,ih)':'if(gt(iw,ih),ih,iw)'\"" \
  --yes-playlist \
  --embed-metadata \
  --download-archive "$archive_path" \
  -o "${playlist_name}/%(playlist_index)03d - %(title)s.%(ext)s" \
  "$url"

# Generate M3U playlist
if [[ -d "$playlist_name" ]]; then
  m3u_file="${playlist_name}.m3u"
  echo "#EXTM3U" > "$m3u_file"
  ls -1 "$playlist_name"/*.mp3 2>/dev/null | sort | while read -r file; do
    echo "$file" >> "$m3u_file"
  done
  echo "Generated playlist: $m3u_file"
fi

# Trigger a media scan of the music directory to allow apps to see the newly added files
am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///storage/emulated/0/Music/
