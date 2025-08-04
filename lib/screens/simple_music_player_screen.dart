import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../simple_music_service.dart';
import '../widgets/simple_mini_player.dart';
import '../widgets/simple_song_list_tile.dart';

class SimpleMusicPlayerScreen extends StatefulWidget {
  const SimpleMusicPlayerScreen({super.key});

  @override
  State<SimpleMusicPlayerScreen> createState() => _SimpleMusicPlayerScreenState();
}

class _SimpleMusicPlayerScreenState extends State<SimpleMusicPlayerScreen> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await context.read<SimpleMusicService>().initialize();
    } catch (e) {
      debugPrint('Error initializing music service: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Music Player'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading music library...',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Requesting permissions and scanning for audio files',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<SimpleMusicService>(
      builder: (context, musicService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Music Player'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            actions: [
              // Shuffle button
              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: musicService.shuffleMode == ShuffleMode.on
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: musicService.toggleShuffle,
                tooltip: 'Shuffle',
              ),
              
              // Repeat button
              IconButton(
                icon: Icon(
                  musicService.getRepeatModeIcon(),
                  color: musicService.repeatMode != RepeatMode.none
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: musicService.toggleRepeatMode,
                tooltip: musicService.getRepeatModeText(),
              ),
              
              IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: () => musicService.pickAudioFiles(),
                tooltip: 'Pick Audio Files',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => musicService.loadSongs(),
                tooltip: 'Scan for Audio Files',
              ),
            ],
          ),
          body: Column(
            children: [
              // Mini player at the top
              if (musicService.currentSong != null)
                const SimpleMiniPlayer(),
              
              // Songs list
              Expanded(
                child: musicService.songs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.music_note,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              musicService.permissionsGranted 
                                  ? 'No songs found'
                                  : 'Permission Required',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              musicService.permissionsGranted
                                  ? 'Make sure you have audio files in your Music, Downloads, or Documents folders.\nTap the folder icon to pick files manually or the refresh icon to scan again.'
                                  : 'This app needs storage permission to scan for music files on your device.\nPlease grant permission to access your music library.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            if (musicService.permissionsGranted)
                              ElevatedButton.icon(
                                onPressed: () => musicService.loadSongs(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Scan Again'),
                              )
                            else
                              Column(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => musicService.loadSongs(),
                                    icon: const Icon(Icons.security),
                                    label: const Text('Grant Permission'),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () => musicService.openSettings(),
                                    icon: const Icon(Icons.settings),
                                    label: const Text('Open Settings'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: musicService.songs.length,
                        itemBuilder: (context, index) {
                          final song = musicService.songs[index];
                          return SimpleSongListTile(
                            song: song,
                            index: index,
                            isCurrentSong: index == musicService.currentIndex,
                            onTap: () => musicService.playSong(index),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}