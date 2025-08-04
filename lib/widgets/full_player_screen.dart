import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_service.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicService>(
      builder: (context, musicService, child) {
        final currentSong = musicService.currentSong;
        if (currentSong == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('No song selected'),
            ),
          );
        }

        final position = _isDragging 
            ? Duration(milliseconds: (_dragValue * (currentSong.duration?.inMilliseconds ?? 0)).round())
            : musicService.position;
        final duration = currentSong.duration ?? Duration.zero;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              children: [
                Text(
                  'Playing from',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  currentSong.album ?? 'Unknown Album',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                
                // Album art
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Song info
                Text(
                  currentSong.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  currentSong.artist ?? 'Unknown Artist',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Progress bar
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _isDragging 
                            ? _dragValue 
                            : (duration.inMilliseconds > 0 
                                ? position.inMilliseconds / duration.inMilliseconds 
                                : 0.0),
                        onChanged: (value) {
                          setState(() {
                            _isDragging = true;
                            _dragValue = value;
                          });
                        },
                        onChangeEnd: (value) {
                          final newPosition = Duration(
                            milliseconds: (value * duration.inMilliseconds).round(),
                          );
                          musicService.seekTo(newPosition);
                          setState(() {
                            _isDragging = false;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            musicService.formatDuration(position),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            musicService.formatDuration(duration),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 40,
                      onPressed: musicService.skipToPrevious,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: IconButton(
                        icon: Icon(
                          musicService.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        iconSize: 50,
                        onPressed: musicService.playPause,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      iconSize: 40,
                      onPressed: musicService.skipToNext,
                    ),
                  ],
                ),
                
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }
}