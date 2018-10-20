import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'action_manager/action_manager.dart';

class VideoPlaybackValue {
  Duration duration;
  Duration position;

  VideoPlaybackValue({@required this.duration, @required this.position});

  VideoPlaybackValue copyWith({
    Duration duration,
    Duration position,
  }) {
    return VideoPlaybackValue(
      duration: duration ?? this.duration,
      position: position ?? this.position,
    );
  }
}

class VideoPlayback extends StatefulWidget {
  VideoPlayback({
    Key key,
    @required this.file,
    bool playing,
    Duration position,
    double volume,
    double speed,
    bool flipped,
    this.onUpdate,
    this.onComplete,
  })  : this.playing = playing ?? true,
        _position = <Duration>[position],
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
  final ValueChanged<VideoPlaybackValue> onUpdate;
  final VoidCallback onComplete;

  @override
  _VideoPlaybackState createState() => new _VideoPlaybackState();
}

class _VideoPlaybackState extends State<VideoPlayback> {
  bool _completeCalled = false;

  VideoPlayerController _controller;

  bool _playing;
  double _volume;
  double _speed;

  @override
  void initState() {
    super.initState();

    VideoPlayerController ctl = new VideoPlayerController.file(widget.file);
    ctl.initialize().then((_) {
      if (!mounted) {
        ctl.dispose();
        return;
      }
      ctl.addListener(_onUpdate);
      _controller = ctl;
      new Timer.periodic(
          new Duration(milliseconds: 1000 ~/ 2 ~/ ActionManager.readFrameRate),
          _onTimer);

      try {
        widget.onUpdate(new VideoPlaybackValue(
            duration: _controller.value.duration,
            position: _controller.value.position));
      } catch (_) {}

      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onUpdate);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return new Center(
        child: const CircularProgressIndicator(),
      );
    }

    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    if (widget.playing != _playing) {
      _playing = widget.playing;
      _playing ? _controller.play() : _controller.pause();
    }
    if (widget._position[0] != null) {
      _controller.seekTo(widget._position[0]);
      widget._position[0] = null;
    }
    if (widget.volume != _volume) {
      _volume = widget.volume;
      _controller.setVolume(_volume);
    }
    if (widget.speed != _speed) {
      _speed = widget.speed;
      _controller.setSpeed(_speed);
    }

    if (!widget.flipped) {
      return new AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: new VideoPlayer(_controller),
      );
    } else {
      return new Transform(
        alignment: Alignment.center,
        transform: new Matrix4.rotationY(pi),
        child: new AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: new VideoPlayer(_controller),
        ),
      );
    }
  }

  bool get _completed {
    if (_controller == null) return false;

    var duration = _controller.value.duration.inMilliseconds;
    if (_controller.value.position.inMilliseconds >= duration - 128)
      return true;

    return false;
  }

  void _onUpdate() {
    if (!mounted) return;

    if (_completed) {
      if (!_completeCalled) {
        _completeCalled = true;
        try {
          widget.onComplete();
        } catch (_) {}
      }
      return;
    }

    if (_controller != null && _controller.value != null) {
      try {
        widget.onUpdate(new VideoPlaybackValue(
            duration: _controller.value.duration,
            position: _controller.value.position));
      } catch (_) {}
    }
  }

  void _onTimer(Timer timer) async {
    if (!mounted) {
      timer.cancel();
      return;
    }

    var position = await _controller.position;

    try {
      widget.onUpdate(new VideoPlaybackValue(
          duration: _controller.value.duration, position: position));
    } catch (_) {}
  }
}
