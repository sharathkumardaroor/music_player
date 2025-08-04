import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_service.dart';
import 'full_player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicService>(
      builder: (context, musicService, child) {
        final currentSong = musicService.currentSong;
        if (currentSong == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const FullPlayerScreen(),
              ),
            );
          },
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Album art
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.music_note,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                
                // Song info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentSong.artist ?? 'Unknown Artist',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Control buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: musicService.skipToPrevious,
                    ),
                    IconButton(
                      icon: Icon(
                        musicService.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: musicService.playPause,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: musicService.skipToNext,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}