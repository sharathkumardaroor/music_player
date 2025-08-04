# Music Player App

A Flutter-based music player app that plays audio files from Android storage with background playback and notification controls.

## Features

- 🎵 **Audio File Playback**: Supports MP3, M4A, AAC, WAV, FLAC, and OGG formats
- 📁 **File Scanning**: Automatically scans common directories for audio files
- 📂 **Manual File Selection**: Pick specific audio files using the file picker
- 🎨 **Modern UI**: Clean, Material Design 3 interface with dark theme
- ⏯️ **Full Player Controls**: Play, pause, skip, seek functionality
- 📱 **Mini Player**: Persistent mini player at the top of the song list

### 🎛️ **Advanced Playback Features**
- 🔀 **Shuffle Mode**: Randomize song order for varied listening experience
- 🔁 **Repeat Modes**: 
  - Repeat None: Play through playlist once
  - Repeat All: Loop entire playlist
  - Repeat One: Repeat current song continuously
- ⏱️ **Song Duration Display**: Shows actual duration of each song in playlist
- ❤️ **Favorites System**: Mark songs as favorites with heart icon
- 🔊 **Volume Control**: Dedicated volume slider in full player screen

### 🎮 **Control Locations**
- **App Bar**: Shuffle and repeat mode toggles
- **Song List**: Individual favorite buttons for each song
- **Mini Player**: Basic play/pause/skip controls
- **Full Player**: Complete control set including volume slider

## How to Use

### First Launch
1. Launch the app
2. Grant storage permissions when prompted
3. The app will automatically scan for audio files in common directories:
   - `/storage/emulated/0/Music`
   - `/storage/emulated/0/Download`
   - `/storage/emulated/0/Documents`

### Adding Music
- **Auto Scan**: Tap the refresh button (🔄) to rescan directories
- **Manual Selection**: Tap the folder button (📁) to pick specific audio files

### Playing Music
- Tap any song in the list to start playing
- Use the mini player at the top for quick controls
- Tap the mini player to open the full player screen
- Music continues playing in the background with notification controls

### Controls
- **Play/Pause**: Control playback
- **Skip Next/Previous**: Navigate between songs (respects repeat/shuffle modes)
- **Seek**: Drag the progress bar to jump to any position
- **Shuffle**: Toggle shuffle mode from app bar or full player
- **Repeat**: Cycle through repeat modes (None → All → One → None)
- **Favorites**: Tap heart icon on any song to add/remove from favorites
- **Volume**: Use volume slider at bottom of full player screen

### Advanced Features Usage
- **Shuffle Mode**: When enabled, songs play in random order
- **Repeat All**: After last song, playlist starts from beginning
- **Repeat One**: Current song loops continuously
- **Favorites**: Favorited songs are saved and persist between app sessions
- **Volume Control**: Adjusts app volume independently of system volume

## Permissions Required

- **READ_EXTERNAL_STORAGE**: To access audio files on the device
- **READ_MEDIA_AUDIO**: For Android 13+ audio file access
- **WAKE_LOCK**: To keep the device awake during playback
- **FOREGROUND_SERVICE**: For background audio playback
- **FOREGROUND_SERVICE_MEDIA_PLAYBACK**: Specific permission for media playback service

## Technical Details

### Architecture
- **State Management**: Provider pattern for reactive UI updates
- **Audio Service**: Background audio service with notification controls
- **Audio Engine**: just_audio plugin for robust audio playback
- **File Access**: Combination of directory scanning and file picker

### Key Components
- `MusicService`: Manages audio files, playback state, and audio service
- `AudioPlayerHandler`: Handles background audio service and media controls
- `MiniPlayer`: Persistent player controls at the top of the screen
- `FullPlayerScreen`: Complete player interface with album art and controls
- `SongListTile`: Individual song items in the playlist

## Building the App

```bash
# Get dependencies
flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

## Supported Audio Formats

- MP3 (.mp3)
- M4A (.m4a)
- AAC (.aac)
- WAV (.wav)
- FLAC (.flac)
- OGG (.ogg)

## Notes

- The app automatically creates a media notification when playing music
- Background playback continues even when the app is closed
- The notification provides play/pause, skip controls
- Audio focus is properly managed for interruptions (calls, other apps)
- The app respects system audio settings and volume controls