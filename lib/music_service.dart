import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'audio_handler.dart';

class AudioFile {
  final String path;
  final String name;
  final String? artist;
  final String? album;
  final Duration? duration;

  AudioFile({
    required this.path,
    required this.name,
    this.artist,
    this.album,
    this.duration,
  });

  String get title => name.replaceAll(RegExp(r'\.[^.]*$'), ''); // Remove file extension
}

class MusicService extends ChangeNotifier {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  AudioPlayerHandler? _audioHandler;
  
  List<AudioFile> _songs = [];
  List<MediaItem> _queue = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  final Duration _duration = Duration.zero;

  // Getters
  List<AudioFile> get songs => _songs;
  List<MediaItem> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  AudioFile? get currentSong => _songs.isNotEmpty && _currentIndex < _songs.length 
      ? _songs[_currentIndex] : null;

  Future<void> initialize() async {
    try {
      _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.example.musicplayer.channel.audio',
          androidNotificationChannelName: 'Music Player',
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
        ),
      );
    } catch (e) {
      debugPrint('Error initializing audio service: $e');
      // Continue without audio service for now
    }

    // Listen to playback state changes
    if (_audioHandler != null) {
      _audioHandler!.playbackState.listen((state) {
        _isPlaying = state.playing;
        _position = state.updatePosition;
        notifyListeners();
      });

      // Listen to media item changes
      _audioHandler!.mediaItem.listen((item) {
        if (item != null) {
          final index = _queue.indexWhere((queueItem) => queueItem.id == item.id);
          if (index != -1) {
            _currentIndex = index;
            notifyListeners();
          }
        }
      });
    }

    await loadSongs();
  }

  Future<bool> requestPermissions() async {
    if (await Permission.storage.isGranted) {
      return true;
    }

    // For Android 13+ (API 33+), use READ_MEDIA_AUDIO
    if (await Permission.audio.isGranted) {
      return true;
    }

    final storageStatus = await Permission.storage.request();
    final audioStatus = await Permission.audio.request();
    
    return storageStatus.isGranted || audioStatus.isGranted;
  }

  Future<void> loadSongs() async {
    try {
      if (!await requestPermissions()) {
        debugPrint('Permission denied');
        return;
      }

      _songs = await _scanForAudioFiles();

      _queue = _songs.map((song) => MediaItem(
        id: song.path,
        album: song.album ?? 'Unknown Album',
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        duration: song.duration ?? Duration.zero,
        extras: {
          'filePath': song.path,
        },
      )).toList();

      if (_audioHandler != null && _queue.isNotEmpty) {
        await _audioHandler!.updateQueue(_queue);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading songs: $e');
    }
  }

  Future<List<AudioFile>> _scanForAudioFiles() async {
    List<AudioFile> audioFiles = [];
    
    // Common audio directories on Android
    List<String> searchPaths = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
      '/sdcard/Music',
      '/sdcard/Download',
    ];

    final audioExtensions = ['.mp3', '.m4a', '.aac', '.wav', '.flac', '.ogg'];

    for (String searchPath in searchPaths) {
      try {
        final directory = Directory(searchPath);
        if (await directory.exists()) {
          await for (FileSystemEntity entity in directory.list(recursive: true)) {
            if (entity is File) {
              final fileName = entity.path.split('/').last.toLowerCase();
              if (audioExtensions.any((ext) => fileName.endsWith(ext))) {
                audioFiles.add(AudioFile(
                  path: entity.path,
                  name: entity.path.split('/').last,
                  artist: 'Unknown Artist',
                  album: 'Unknown Album',
                ));
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error scanning directory $searchPath: $e');
      }
    }

    return audioFiles;
  }

  Future<void> pickAudioFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        List<AudioFile> newSongs = result.files.map((file) => AudioFile(
          path: file.path!,
          name: file.name,
          artist: 'Unknown Artist',
          album: 'Unknown Album',
        )).toList();

        _songs.addAll(newSongs);
        
        _queue = _songs.map((song) => MediaItem(
          id: song.path,
          album: song.album ?? 'Unknown Album',
          title: song.title,
          artist: song.artist ?? 'Unknown Artist',
          duration: song.duration ?? Duration.zero,
          extras: {
            'filePath': song.path,
          },
        )).toList();

        if (_audioHandler != null && _queue.isNotEmpty) {
          await _audioHandler!.updateQueue(_queue);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking audio files: $e');
    }
  }

  Future<void> play() async {
    if (_audioHandler != null) {
      await _audioHandler!.play();
    }
  }

  Future<void> pause() async {
    if (_audioHandler != null) {
      await _audioHandler!.pause();
    }
  }

  Future<void> playPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> skipToNext() async {
    if (_audioHandler != null) {
      await _audioHandler!.skipToNext();
    }
  }

  Future<void> skipToPrevious() async {
    if (_audioHandler != null) {
      await _audioHandler!.skipToPrevious();
    }
  }

  Future<void> seekTo(Duration position) async {
    if (_audioHandler != null) {
      await _audioHandler!.seek(position);
    }
  }

  Future<void> playSong(int index) async {
    if (index >= 0 && index < _queue.length && _audioHandler != null) {
      _currentIndex = index;
      await _audioHandler!.skipToQueueItem(index);
      await play();
      notifyListeners();
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}