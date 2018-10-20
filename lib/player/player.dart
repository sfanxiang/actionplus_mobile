import 'dart:io';

import 'package:flutter/material.dart';

import '../video_playback.dart';
import 'player_control.dart';

class Player extends StatefulWidget {
  Player({
    Key key,
    @required this.file,
    this.playing,
    Duration position,
    double volume,
    double speed,
    bool flipped,
    this.overlay,
    this.onUpdate,
    this.onSeek,
    this.onComplete,
    this.onStop,
  })  : _position = <Duration>[position],
        this.volume = volume ?? 1.0,
        this.speed = speed ?? 1.0,
        this.flipped = flipped ?? false,
        super(key: key);

  final File file;
  final bool playing;
  final List<Duration> _position;
  final double volume;
  final double speed;
  final bool flipped;
  final Widget overlay;
  final ValueChanged<VideoPlaybackValue> onUpdate;
  final ValueChanged<VideoPlaybackValue> onSeek;
  final VoidCallback onComplete;
  final VoidCallback onStop;

  @override
  _PlayerState createState() => new _PlayerState();
}

class _PlayerState extends State<Player> {
  VideoPlaybackValue _playbackValue;
  Duration _setPosition;
  bool _playing = true;
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    if (widget.playing != null) _playing = widget.playing; // Enforced state

    Duration currentPosition = widget._position[0];
    widget._position[0] = null;

    if (currentPosition == null) currentPosition = _setPosition;
    _setPosition = null;

    double displayPosition = 0.0;
    if (_playbackValue != null) {
      if (currentPosition != null) {
        displayPosition = currentPosition.inMilliseconds /
            _playbackValue.duration.inMilliseconds;
      } else {
        displayPosition = _playbackValue.position.inMilliseconds /
            _playbackValue.duration.inMilliseconds;
      }
    }
    displayPosition = displayPosition.clamp(0.0, 1.0);

    return new Column(
      children: <Widget>[
        new Expanded(
          child: new Center(
            child: new Stack(
              children: <Widget>[
                new VideoPlayback(
                  file: widget.file,
                  playing: _playing,
                  position: currentPosition,
                  volume: !_finished ? widget.volume : 0.0,
                  speed: widget.speed,
                  flipped: widget.flipped,
                  onUpdate: _onUpdate,
                  onComplete: _onComplete,
                ),
                new Positioned.fill(
                  child:
                      widget.overlay ?? new Container(height: 0.0, width: 0.0),
                ),
              ],
            ),
          ),
        ),
        new PlayerControl(
          playing: _playing,
          position: displayPosition,
          onPlayPause: () {
            if (!mounted) return;
            _playing = !_playing;
            setState(() {});
          },
          onSeek: (value) {
            if (!mounted) return;
            if (_playbackValue != null) {
              Duration position = new Duration(
                  milliseconds: (value.clamp(0.0, 1.0) *
                          _playbackValue.duration.inMilliseconds)
                      .truncate());
              _setPosition = position;
              try {
                widget.onSeek(_playbackValue.copyWith(position: position));
              } catch (_) {}
            }
            setState(() {});
          },
          onStop: _onStop,
        ),
      ],
    );
  }

  void _onUpdate(VideoPlaybackValue value) {
    if (!mounted) return;

    _playbackValue = value;
    setState(() {});
    try {
      widget.onUpdate(value);
    } catch (_) {}
  }

  void _onComplete() {
    if (!mounted) return;
    if (_finished) return;

    _finished = true;
    setState(() {});
    try {
      widget.onComplete();
    } catch (_) {}
  }

  void _onStop() {
    if (!mounted) return;
    if (_finished) return;

    _finished = true;
    setState(() {});
    try {
      widget.onStop();
    } catch (_) {}
  }
}
