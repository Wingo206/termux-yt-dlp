#!/bin/bash
echo "yt-dlp termux script"

cd ~/storage/shared/Music

archives_dir="/data/data/com.termux/files/home/archives"
mkdir -p $archives_dir

dialog_data=$(termux-dialog -t "Enter Youtube Playlist URL")

code=$(jq -r '.code'  <<<"$dialog_data")
url=$(jq -r '.text'  <<<"$dialog_data")

if [[ $code -eq -2 ]]; then
  echo "User cancelled."
  exit 1
fi

playlist_id=$(echo "$url" | grep -oP '(?<=list=)[^&]+')
archive_path="${archives_dir}/${playlist_id}_archive.txt"

#Clear the archive?
clear_archive_dialog=$(termux-dialog checkbox -t "Clear the download archive?" -v"clear archive")

code=$(jq -r '.code'  <<<"$clear_archive_dialog")
text=$(jq -r '.text'  <<<"$clear_archive_dialog")

if [[ $code -eq -2 ]]; then
  echo "User cancelled."
  exit 1
fi
if [[ $text == "[clear archive]" ]]; then
  echo "Removing $archive_path"
  rm -f "$archive_path"
fi

echo "Downloading playlist with URL: $url"

python ~/yt-dlp -x \
  --audio-format mp3 \
  --embed-thumbnail \
  --yes-playlist \
  --embed-metadata \
  --download-archive $archive_path \
  -o "%(playlist_title)s/%(playlist_index)03d - %(title)s.%(ext)s" \
  $url

# Trigger a media scan of the music directory to allow apps to see the newly added files
am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///storage/emulated/0/Music/
