import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPlusValue {
  Duration duration;
  Duration position;

  VideoPlayerPlusValue({@required this.duration, @required this.position});
}

class VideoPlayerPlus extends StatefulWidget {
  VideoPlayerPlus({
    Key key,
    @required this.file,
    Duration position,
    double volume,
    double speed,
    this.onUpdated,
    this.onCompleted,
  })  : _position = <Duration>[position],
        this.volume = volume ?? 1.0,
        this.speed = speed ?? 1.0,
        super(key: key);

  final File file;
  final List<Duration> _position;
  final double volume;
  final double speed;
  final ValueChanged<VideoPlayerPlusValue> onUpdated;
  final VoidCallback onCompleted;

  @override
  _VideoPlayerPlusState createState() => new _VideoPlayerPlusState();
}

class _VideoPlayerPlusState extends State<VideoPlayerPlus> {
  bool _completeCalled = false;

  VideoPlayerController _controller;

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
      _controller = ctl;
      _controller.addListener(_onUpdate);
      new Timer.periodic(new Duration(milliseconds: 100), _onTimer);

      try {
        widget.onUpdated(new VideoPlayerPlusValue(
            duration: _controller.value.duration,
            position: _controller.value.position));
      } catch (_) {}

      setState(() {});
    });
  }

  @override
  void dispose() {
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
    if (widget._position[0] != null) {
      _controller.seekTo(widget._position[0]);
      widget._position[0] = null;
    }
    if (widget.volume != _volume) {
      _volume = widget.volume;
      _controller.setVolume(_volume);
    }
    if (widget.speed != _speed) {
      if (widget.speed == 1.0 && !_controller.value.isPlaying) {
        _controller.play();
      } else if (widget.speed != 1.0 && _controller.value.isPlaying) {
        _controller.pause();
      }
      _speed = widget.speed;
    }

    return new AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: new VideoPlayer(_controller),
    );
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
          widget.onCompleted();
        } catch (_) {}
      }
      return;
    }

    if (_controller != null && _controller.value != null) {
      try {
        widget.onUpdated(new VideoPlayerPlusValue(
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

    if (_controller == null || _speed == null) return;
    if (_speed < 0.4) return;

    var duration = _controller.value.duration.inMilliseconds;
    var positionDuration = await _controller.position;
    var position = positionDuration.inMilliseconds;

    if (_speed == 1.0) {
      try {
        widget.onUpdated(new VideoPlayerPlusValue(
            duration: _controller.value.duration, position: positionDuration));
      } catch (_) {}
      return;
    }

    if (position + (100 * _speed).truncate() < duration) {
      _controller.seekTo(
          new Duration(milliseconds: position + (100 * _speed).truncate()));
    } else {
      _controller.seekTo(new Duration(milliseconds: max(duration - 1, 0)));
    }
  }
}
