import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_service.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_list_tile.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicService>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicService>(
      builder: (context, musicService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Music Player'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            actions: [
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
                const MiniPlayer(),
              
              // Songs list
              Expanded(
                child: musicService.songs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_note,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No songs found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Make sure you have audio files on your device',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: musicService.songs.length,
                        itemBuilder: (context, index) {
                          final song = musicService.songs[index];
                          return SongListTile(
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