import 'dart:io';

import 'package:flutter/material.dart';

import '../video_playback.dart';
import 'player_control.dart';

class DualPlayer extends StatefulWidget {
  DualPlayer({
    Key key,
    @required this.sampleFile,
    @required this.standardFile,
    this.playing,
    Duration position,
    double volume,
    double speed,
    bool flipped,
    this.sampleOverlay,
    this.standardOverlay,
    this.onUpdate,
    this.onSeek,
    this.onComplete,
    this.onStop,
  })  : _position = <Duration>[position],
        this.volume = volume ?? 1.0,
        this.speed = speed ?? 1.0,
        this.flipped = flipped ?? false,
        super(key: key);

  final File sampleFile;
  final File standardFile;
  final bool playing;
  final List<Duration> _position;
  final double volume;
  final double speed;
  final bool flipped;
  final Widget sampleOverlay;
  final Widget standardOverlay;
  final ValueChanged<VideoPlaybackValue> onUpdate;
  final ValueChanged<VideoPlaybackValue> onSeek;
  final VoidCallback onComplete;
  final VoidCallback onStop;

  @override
  _DualPlayerState createState() => new _DualPlayerState();
}

class _DualPlayerState extends State<DualPlayer> {
  VideoPlaybackValue _samplePlaybackValue;
  VideoPlaybackValue _standardPlaybackValue;
  Duration _setPosition = new Duration(milliseconds: 0);
  bool _playing = true;
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    if (widget.playing != null) _playing = widget.playing; // Enforced state

    // Don't play until both tracks are ready
    bool currentPlaying = _playing;
    if (_samplePlaybackValue == null || _standardPlaybackValue == null)
      currentPlaying = false;

    Duration currentPosition = widget._position[0];
    widget._position[0] = null;

    if (currentPosition == null) currentPosition = _setPosition;
    _setPosition = null;

    double displayPosition = 0.0;
    if (_samplePlaybackValue != null) {
      if (currentPosition != null) {
        displayPosition = currentPosition.inMilliseconds /
            _samplePlaybackValue.duration.inMilliseconds;
      } else {
        displayPosition = _samplePlaybackValue.position.inMilliseconds /
            _samplePlaybackValue.duration.inMilliseconds;
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
                  file: widget.standardFile,
                  playing: currentPlaying,
                  position: currentPosition,
                  volume: !_finished && currentPlaying ? widget.volume : 0.0,
                  speed: widget.speed,
                  flipped: widget.flipped,
                  onUpdate: _onStandardUpdate,
                  onComplete: _onComplete,
                ),
                new Positioned.fill(
                  child: widget.standardOverlay ??
                      new Container(height: 0.0, width: 0.0),
                ),
              ],
            ),
          ),
        ),
        new PlayerControl(
          // This playing status is for display
          playing: _playing,
          position: displayPosition,
          onPlayPause: () {
            if (!mounted) return;

            _playing = !_playing;

            // Take the chance to sync the tracks
            if (!_playing &&
                _samplePlaybackValue != null &&
                _standardPlaybackValue != null) {
              if (_samplePlaybackValue.position.inMilliseconds <
                  _standardPlaybackValue.duration.inMilliseconds) {
                _setPosition = new Duration(
                    milliseconds: _samplePlaybackValue.position.inMilliseconds);
              }
            }

            setState(() {});
          },
          onSeek: (value) {
            if (!mounted) return;

            if (_samplePlaybackValue != null) {
              Duration position = new Duration(
                  milliseconds: (value.clamp(0.0, 1.0) *
                          _samplePlaybackValue.duration.inMilliseconds)
                      .truncate());
              _setPosition = position;

              // Seeking might cause the tracks to be out-of-sync, so we pause
              // here if we can.
              _playing = false;

              try {
                widget
                    .onSeek(_samplePlaybackValue.copyWith(position: position));
              } catch (_) {}
            }

            setState(() {});
          },
          onStop: _onStop,
        ),
        new Expanded(
          child: new Center(
            child: new Stack(
              children: <Widget>[
                new VideoPlayback(
                  file: widget.sampleFile,
                  playing: currentPlaying,
                  position: currentPosition,
                  volume: 0.0,
                  speed: widget.speed,
                  flipped: widget.flipped,
                  onUpdate: _onSampleUpdate,
                  onComplete: _onComplete,
                ),
                new Positioned.fill(
                  child: widget.sampleOverlay ??
                      new Container(height: 0.0, width: 0.0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onSampleUpdate(VideoPlaybackValue value) {
    if (!mounted) return;

    _samplePlaybackValue = value;
    setState(() {});
    try {
      widget.onUpdate(value);
    } catch (_) {}
  }

  void _onStandardUpdate(VideoPlaybackValue value) {
    if (!mounted) return;

    _standardPlaybackValue = value;
    setState(() {});
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
