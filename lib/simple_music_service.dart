import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:math';

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
  
  String get id => path; // Use path as unique identifier
}

enum RepeatMode { none, one, all }

enum ShuffleMode { off, on }

class SimpleMusicService extends ChangeNotifier {
  static final SimpleMusicService _instance = SimpleMusicService._internal();
  factory SimpleMusicService() => _instance;
  SimpleMusicService._internal();

  final AudioPlayer _player = AudioPlayer();
  
  List<AudioFile> _songs = [];
  List<AudioFile> _originalSongs = []; // Keep original order for shuffle
  List<int> _shuffleIndices = []; // Shuffle order
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  
  // New features
  RepeatMode _repeatMode = RepeatMode.none;
  ShuffleMode _shuffleMode = ShuffleMode.off;
  Set<String> _favorites = <String>{};
  double _volume = 1.0;

  // Getters
  List<AudioFile> get songs => _songs;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  RepeatMode get repeatMode => _repeatMode;
  ShuffleMode get shuffleMode => _shuffleMode;
  Set<String> get favorites => _favorites;
  double get volume => _volume;
  AudioFile? get currentSong => _songs.isNotEmpty && _currentIndex < _songs.length 
      ? _songs[_currentIndex] : null;
  
  // Permission status
  bool _permissionsGranted = false;
  bool get permissionsGranted => _permissionsGranted;

  Future<void> initialize() async {
    debugPrint('Initializing SimpleMusicService...');
    
    // Load preferences
    await _loadPreferences();
    
    // Set initial volume
    await _player.setVolume(_volume);
    
    // Listen to player state changes
    _player.playerStateStream.listen((playerState) {
      _isPlaying = playerState.playing;
      notifyListeners();
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    // Listen to playback completion
    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _handleSongCompletion();
      }
    });

    // Automatically load songs on initialization
    debugPrint('Auto-loading songs on initialization...');
    await loadSongs();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _repeatMode = RepeatMode.values[prefs.getInt('repeat_mode') ?? 0];
    _shuffleMode = ShuffleMode.values[prefs.getInt('shuffle_mode') ?? 0];
    _volume = prefs.getDouble('volume') ?? 1.0;
    _favorites = prefs.getStringList('favorites')?.toSet() ?? <String>{};
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('repeat_mode', _repeatMode.index);
    await prefs.setInt('shuffle_mode', _shuffleMode.index);
    await prefs.setDouble('volume', _volume);
    await prefs.setStringList('favorites', _favorites.toList());
  }

  Future<bool> requestPermissions() async {
    try {
      debugPrint('Checking current permissions...');
      
      // Check if permissions are already granted
      bool hasStoragePermission = await Permission.storage.isGranted;
      bool hasAudioPermission = await Permission.audio.isGranted;
      
      debugPrint('Storage permission: $hasStoragePermission');
      debugPrint('Audio permission: $hasAudioPermission');
      
      if (hasStoragePermission || hasAudioPermission) {
        debugPrint('Permissions already granted');
        return true;
      }

      debugPrint('Requesting permissions...');
      
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.audio,
      ].request();

      debugPrint('Permission request results:');
      debugPrint('Storage: ${statuses[Permission.storage]}');
      debugPrint('Audio: ${statuses[Permission.audio]}');

      // Check if any permission was granted
      bool granted = statuses[Permission.storage]?.isGranted == true ||
                    statuses[Permission.audio]?.isGranted == true;
      
      if (!granted) {
        debugPrint('All permissions denied by user');
        // Check if permanently denied
        bool storagePermanentlyDenied = statuses[Permission.storage]?.isPermanentlyDenied == true;
        bool audioPermanentlyDenied = statuses[Permission.audio]?.isPermanentlyDenied == true;
        
        if (storagePermanentlyDenied || audioPermanentlyDenied) {
          debugPrint('Permissions permanently denied - user needs to enable in settings');
        }
      } else {
        debugPrint('At least one permission granted');
      }
      
      _permissionsGranted = granted;
      return granted;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      _permissionsGranted = false;
      return false;
    }
  }

  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }

  Future<void> loadSongs() async {
    try {
      debugPrint('Starting to load songs...');
      
      if (!await requestPermissions()) {
        debugPrint('Permission denied - cannot load songs');
        notifyListeners();
        return;
      }

      debugPrint('Permissions granted, scanning for audio files...');
      _songs = await _scanForAudioFiles();
      _originalSongs = List.from(_songs);
      _generateShuffleIndices();
      
      debugPrint('Found ${_songs.length} songs');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading songs: $e');
      notifyListeners();
    }
  }

  Future<List<AudioFile>> _scanForAudioFiles() async {
    List<AudioFile> audioFiles = [];
    
    debugPrint('Starting directory-based audio file scanning...');
    
    // Common audio directories on Android
    List<String> searchPaths = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads', // Alternative Downloads folder
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/DCIM', // Sometimes audio files are here
      '/storage/emulated/0/Android/data', // App-specific folders
      '/sdcard/Music',
      '/sdcard/Download',
      '/sdcard/Downloads',
    ];

    final audioExtensions = ['.mp3', '.m4a', '.aac', '.wav', '.flac', '.ogg', '.wma'];

    for (String searchPath in searchPaths) {
      try {
        debugPrint('Scanning directory: $searchPath');
        final directory = Directory(searchPath);
        
        if (await directory.exists()) {
          debugPrint('Directory exists: $searchPath');
          int filesInDir = 0;
          
          await for (FileSystemEntity entity in directory.list(recursive: true)) {
            if (entity is File) {
              final fileName = entity.path.split('/').last.toLowerCase();
              if (audioExtensions.any((ext) => fileName.endsWith(ext))) {
                filesInDir++;
                
                // Get file stats for additional info
                FileStat stat = await entity.stat();
                
                audioFiles.add(AudioFile(
                  path: entity.path,
                  name: entity.path.split('/').last,
                  artist: 'Unknown Artist',
                  album: 'Unknown Album',
                  duration: null, // Skip duration calculation for performance
                ));
              }
            }
          }
          
          debugPrint('Found $filesInDir audio files in $searchPath');
        } else {
          debugPrint('Directory does not exist: $searchPath');
        }
      } catch (e) {
        debugPrint('Error scanning directory $searchPath: $e');
      }
    }

    debugPrint('Total audio files found: ${audioFiles.length}');
    return audioFiles;
  }

  Future<void> pickAudioFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        List<AudioFile> newSongs = [];
        for (var file in result.files) {
          // Try to get duration
          Duration? duration;
          try {
            final tempPlayer = AudioPlayer();
            await tempPlayer.setFilePath(file.path!);
            duration = tempPlayer.duration;
            await tempPlayer.dispose();
          } catch (e) {
            debugPrint('Error getting duration for ${file.path}: $e');
          }
          
          newSongs.add(AudioFile(
            path: file.path!,
            name: file.name,
            artist: 'Unknown Artist',
            album: 'Unknown Album',
            duration: duration,
          ));
        }

        _songs.addAll(newSongs);
        _originalSongs = List.from(_songs);
        _generateShuffleIndices();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking audio files: $e');
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> playPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> skipToNext() async {
    int nextIndex = _getNextIndex();
    if (nextIndex != -1) {
      await playSong(nextIndex);
    }
  }

  Future<void> skipToPrevious() async {
    int prevIndex = _getPreviousIndex();
    if (prevIndex != -1) {
      await playSong(prevIndex);
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> playSong(int index) async {
    if (index >= 0 && index < _songs.length) {
      _currentIndex = index;
      final song = _songs[index];
      await _player.setFilePath(song.path);
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

  // New functionality methods
  void toggleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.none:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.none;
        break;
    }
    _savePreferences();
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffleMode = _shuffleMode == ShuffleMode.off ? ShuffleMode.on : ShuffleMode.off;
    if (_shuffleMode == ShuffleMode.on) {
      _generateShuffleIndices();
    } else {
      // Return to original order
      _songs = List.from(_originalSongs);
      // Find current song in original list
      if (currentSong != null) {
        _currentIndex = _originalSongs.indexWhere((song) => song.path == currentSong!.path);
      }
    }
    _savePreferences();
    notifyListeners();
  }

  void toggleFavorite(String songId) {
    if (_favorites.contains(songId)) {
      _favorites.remove(songId);
    } else {
      _favorites.add(songId);
    }
    _savePreferences();
    notifyListeners();
  }

  bool isFavorite(String songId) {
    return _favorites.contains(songId);
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    _savePreferences();
    notifyListeners();
  }

  void _generateShuffleIndices() {
    if (_songs.isEmpty) return;
    
    _shuffleIndices = List.generate(_songs.length, (index) => index);
    _shuffleIndices.shuffle(Random());
    
    if (_shuffleMode == ShuffleMode.on) {
      // Reorder songs based on shuffle indices
      final shuffledSongs = <AudioFile>[];
      for (int index in _shuffleIndices) {
        if (index < _originalSongs.length) {
          shuffledSongs.add(_originalSongs[index]);
        }
      }
      _songs = shuffledSongs;
      
      // Update current index if we have a current song
      if (currentSong != null) {
        _currentIndex = _songs.indexWhere((song) => song.path == currentSong!.path);
      }
    }
  }

  int _getNextIndex() {
    if (_songs.isEmpty) return -1;
    
    if (_repeatMode == RepeatMode.one) {
      return _currentIndex; // Stay on same song
    }
    
    if (_currentIndex < _songs.length - 1) {
      return _currentIndex + 1;
    } else if (_repeatMode == RepeatMode.all) {
      return 0; // Loop back to first song
    }
    
    return -1; // No next song
  }

  int _getPreviousIndex() {
    if (_songs.isEmpty) return -1;
    
    if (_repeatMode == RepeatMode.one) {
      return _currentIndex; // Stay on same song
    }
    
    if (_currentIndex > 0) {
      return _currentIndex - 1;
    } else if (_repeatMode == RepeatMode.all) {
      return _songs.length - 1; // Loop to last song
    }
    
    return -1; // No previous song
  }

  void _handleSongCompletion() {
    if (_repeatMode == RepeatMode.one) {
      // Replay the same song
      _player.seek(Duration.zero);
      _player.play();
    } else {
      // Move to next song
      skipToNext();
    }
  }

  String getRepeatModeText() {
    switch (_repeatMode) {
      case RepeatMode.none:
        return 'Repeat Off';
      case RepeatMode.all:
        return 'Repeat All';
      case RepeatMode.one:
        return 'Repeat One';
    }
  }

  IconData getRepeatModeIcon() {
    switch (_repeatMode) {
      case RepeatMode.none:
        return Icons.repeat;
      case RepeatMode.all:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}