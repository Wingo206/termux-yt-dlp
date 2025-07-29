# termux-yt-dlp
Script and setup to run yt-dlp for music playlists on Termux

# Setup Instructions
- Install Termux: https://github.com/termux/termux-app/releases
- Install Termux widget: https://github.com/termux/termux-widget/releases
- Install Termux API: https://github.com/termux/termux-api/actions/workflows/github_action_build.yml?query=branch%3Amaster+event%3Apush (Click on a build and go to artifacts)
- Go to Termux
- pkg update
- pkg install git
- pkg install python
- pkg install ffmpeg
- pkg install termux-api
- pkg install jq
- termux-setup-storage
- git clone https://github.com/Wingo206/termux-yt-dlp.git
- curl -L -O https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp
- mkdir ~/.shortcuts
- cp ./termux-yt-dlp/download-yt.sh ~/.shortcuts/download-yt.sh

- Add the Termux widget to your home screen

# Usage
- Click the download-yt.sh script on the widget
- Input the YouTube playlist URL into the dialog
- Toggle clear archive if you want to redownload the entire playlist. Otherwise, it will only download videos that weren't downloaded yet.
- Downloads go into Music/
