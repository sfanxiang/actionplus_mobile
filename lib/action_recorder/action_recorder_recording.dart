import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../action_manager/action_manager.dart';
import '../actionplus_localizations.dart';

class ActionRecorderRecordingResult {
  ActionRecorderRecordingResult({@required this.saved, this.path});

  final bool saved;
  final String path;
}

class ActionRecorderRecording extends StatefulWidget {
  // note: never unmount this widget before onFinished is called!
  ActionRecorderRecording({
    Key key,
    @required this.cameraController,
    @required this.onFinished,
    this.standardId,
  }) : super(key: key);

  final CameraController cameraController;
  final ValueChanged<ActionRecorderRecordingResult> onFinished;
  final String standardId;

  @override
  _ActionRecorderRecordingState createState() =>
      new _ActionRecorderRecordingState();
}

class _ActionRecorderRecordingState extends State<ActionRecorderRecording> {
  String _path;

  bool _activated = false;
  int _countDown = 3;
  bool _started = false;
  bool _finished = false;

  VideoPlayerController _playerController;
  VideoPlayerController _pendingDisposePlayerController;

  @override
  void initState() {
    super.initState();

    // TODO: use a separate directory (e.g. app_tmp) for this so that it is managed by the dart code and cleaned up on each app start, as opposed to the C++ initialization
    // TODO: don't hard code .mp4 format
    _path =
        ActionManager.dataPath + '/tmp/recording_' + new Uuid().v4() + '.mp4';

    if (widget.standardId != null && widget.standardId != '') {
      ActionManager.video(widget.standardId).then((filePath) {
        VideoPlayerController controller =
            new VideoPlayerController.file(new File(filePath));
        controller.initialize().then((_) {
          if (!mounted) return;

          _playerController = controller;
          setState(() {});
        });
      });
    }
  }

  @override
  void dispose() {
    _playerController?.dispose();
    _pendingDisposePlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.standardId == null || widget.standardId == '') {
      return new Stack(
        children: <Widget>[
          buildRecorder(context),
          _countDown < 0 && _started && !_finished
              ? new Align(
                  alignment: Alignment.bottomCenter,
                  child: new FloatingActionButton(
                      child: new Icon(Icons.stop),
                      foregroundColor: Colors.deepOrange,
                      backgroundColor: Colors.deepPurple,
                      onPressed: _stopVideoRecording),
                )
              : new Container(height: 0.0, width: 0.0),
        ],
      );
    } else {
      if (_finished) return new Center(child: new CircularProgressIndicator());

      if (_playerController == null) {
        return new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new CircularProgressIndicator(),
              new FlatButton(
                child: new Text(
                  'Stop loading'.toUpperCase(),
                  style: new TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  if (!mounted || _finished) return;
                  if (_playerController != null) return;

                  _finished = true;
                  try {
                    widget.onFinished(
                        new ActionRecorderRecordingResult(saved: false));
                  } catch (_) {}
                },
              ),
            ],
          ),
        );
      }

      return new Stack(
        children: <Widget>[
          new Column(
            children: <Widget>[
              new Expanded(child: new Center(child: buildStandard(context))),
              buildProgress(context),
              new Expanded(child: new Center(child: buildRecorder(context))),
            ],
          ),
          _countDown < 0 && _started && !_finished
              ? new Align(
                  alignment: Alignment.centerRight,
                  child: new FloatingActionButton(
                      child: new Icon(Icons.stop),
                      foregroundColor: Colors.deepOrange,
                      backgroundColor: Colors.deepPurple,
                      onPressed: _stopVideoRecording),
                )
              : new Container(height: 0.0, width: 0.0),
        ],
      );
    }
  }

  void doCountDown() {
    if (!mounted) return;

    if (_countDown == 0) {
      widget.cameraController.startVideoRecording(_path).then((_) {
        _started = true;

        if (widget.standardId != null &&
            widget.standardId != '' &&
            _playerController != null) {
          _playerController.play().then((_) {
            if (_playerController != null) {
              _playerController.addListener(() {
                if (!mounted) return;
                if (_playerController == null) return;

                setState(() {});

                if (!_playerController.value.isPlaying) {
                  _stopVideoRecording();
                }
              });
            }
          });
          // Some players don't support completion.
          new Future.delayed(
              _playerController.value.duration, _stopVideoRecording);
        }

        if (mounted) {
          setState(() {});
        }
      }).catchError((_) {
        _finished = true;

        if (mounted) {
          setState(() {});
          widget.onFinished(new ActionRecorderRecordingResult(saved: false));
        }
      });
    }

    if (_countDown >= 0) {
      setState(() {
        _countDown--;
      });
    }

    if (_countDown >= 0) {
      new Timer(new Duration(seconds: 1), doCountDown);
    }
  }

  void _stopVideoRecording() {
    if (_finished || !mounted) return;

    setState(() => _finished = true);

    if (_playerController != null) {
      _pendingDisposePlayerController = _playerController;
      _playerController = null;
      try {
        _pendingDisposePlayerController.pause().catchError((_) {});
      } catch (_) {}
    }

    widget.cameraController.stopVideoRecording().then((_) {
      if (mounted)
        widget.onFinished(new ActionRecorderRecordingResult(
          saved: true,
          path: _path,
        ));
    }).catchError((_) {
      if (mounted)
        widget.onFinished(new ActionRecorderRecordingResult(saved: false));
    });
  }

  Widget buildRecorder(BuildContext context) {
    if (!_activated) {
      _activated = true;
      new Timer(new Duration(seconds: 1), doCountDown);
    }

    if (_countDown > 0) {
      return new Center(
        child: new Text(
          _countDown.toString(),
          style: new TextStyle(fontSize: 96.0, color: Colors.white),
          textScaleFactor: 1.0,
        ),
      );
    } else if (_countDown == 0 || (_countDown < 0 && !_started && !_finished)) {
      return new Center(
        child: new Text(
          ActionplusLocalizations.of(context).go.toUpperCase(),
          style: new TextStyle(fontSize: 96.0, color: Colors.white),
          textScaleFactor: 1.0,
        ),
      );
    } else if (_started && !_finished) {
      return new Align(
        alignment: AlignmentDirectional.center,
        child: new AspectRatio(
          aspectRatio: widget.cameraController.value.aspectRatio,
          child: new CameraPreview(widget.cameraController),
        ),
      );
    } else {
      // Finished.
      return new Center(child: new CircularProgressIndicator());
    }
  }

  Widget buildStandard(BuildContext context) {
    if (widget.standardId == null ||
        widget.standardId == '' ||
        _playerController == null) {
      return new Container();
    }

    if (widget.cameraController.description.lensDirection ==
            CameraLensDirection.front ||
        widget.cameraController.description.lensDirection ==
            CameraLensDirection.external) {
      return new Transform(
        alignment: Alignment.center,
        transform: new Matrix4.rotationY(pi),
        child: new AspectRatio(
          aspectRatio: _playerController.value.aspectRatio,
          child: new VideoPlayer(_playerController),
        ),
      );
    } else {
      return new AspectRatio(
        aspectRatio: _playerController.value.aspectRatio,
        child: new VideoPlayer(_playerController),
      );
    }
  }

  Widget buildProgress(BuildContext context) {
    int playerDuration = _playerController.value.duration.inMilliseconds;
    if (playerDuration == 0) playerDuration = 1;

    return new LinearProgressIndicator(
      value: min(
        _playerController.value.position.inMilliseconds.toDouble() /
            playerDuration.toDouble(),
        1.0,
      ),
    );
  }
}
