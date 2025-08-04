import 'package:flutter/material.dart';
import '../music_service.dart';

class SongListTile extends StatelessWidget {
  final AudioFile song;
  final int index;
  final bool isCurrentSong;
  final VoidCallback onTap;

  const SongListTile({
    super.key,
    required this.song,
    required this.index,
    required this.isCurrentSong,
    required this.onTap,
  });

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
        child: Icon(
          Icons.music_note,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        song.title,
        style: TextStyle(
          fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
          color: isCurrentSong 
              ? Theme.of(context).colorScheme.primary 
              : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            song.artist ?? 'Unknown Artist',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${song.album ?? 'Unknown Album'} • ${_formatDuration(song.duration)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: isCurrentSong
          ? Icon(
              Icons.equalizer,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}