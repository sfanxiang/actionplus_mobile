import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../action_manager/action_manager.dart';

// TODO: Some Android devices doesn't support playing two videos at the same time.
//       In the long run, offer a setting to turn off dual playback.

class ActionPlayer extends StatefulWidget {
  ActionPlayer({Key key, @required this.id, this.standardId, this.onFinished})
      : super(key: key);

  final String id;
  final String standardId;
  final VoidCallback onFinished;

  @override
  _ActionPlayerState createState() => new _ActionPlayerState();
}

class _ActionPlayerState extends State<ActionPlayer> {
  bool init = false;
  bool finishedCalled = false;

  String sampleVideo, standardVideo;

  VideoPlayerController sampleController, standardController;
  VideoPlayerController _initSampleController, _initStandardController;

  @override
  void initState() {
    super.initState();

    () async {
      try {
        sampleVideo = await ActionManager.video(widget.id);
        standardVideo = widget.standardId != null
            ? await ActionManager.video(widget.standardId)
            : null;
        if (sampleVideo == '') {
          sampleVideo = null;
          throw new Exception();
        }
        if (standardVideo == '') standardVideo = null;
      } catch (_) {
        if (!mounted) return;
        if (!finishedCalled) {
          try {
            widget.onFinished();
          } catch (_) {}
        }
        return;
      }

      initPlayback();
    }();
  }

  void initPlayback() {
    Function tryFinishInit = () {
      if (!mounted) {
        if (_initSampleController != null) {
          try {
            _initSampleController.dispose();
          } catch (_) {}
          _initSampleController = null;
        }
        if (_initStandardController != null) {
          try {
            _initStandardController.dispose();
          } catch (_) {}
          _initStandardController = null;
        }
        return;
      }

      if (_initSampleController == null) return;
      if (standardVideo != null && _initStandardController == null) return;

      sampleController = _initSampleController;
      _initSampleController = null;
      standardController = _initStandardController;
      _initStandardController = null;

      sampleController.play();
      standardController?.play();

      init = true;

      setState(() {});
    };

    var controller = new VideoPlayerController.file(new File(sampleVideo));
    controller.initialize().then((_) {
      controller.addListener(onUpdate);

      if (standardVideo != null) {
        controller.setVolume(0.0).then((_) {
          _initSampleController = controller;
          tryFinishInit();
        });
      } else {
        _initSampleController = controller;
        tryFinishInit();
      }
    });

    if (standardVideo != null) {
      var controller = new VideoPlayerController.file(new File(standardVideo));
      controller.initialize().then((_) {
        controller.addListener(onUpdate);
        _initStandardController = controller;

        tryFinishInit();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in [
      sampleController,
      standardController,
      _initSampleController,
      _initStandardController
    ]) {
      controller?.dispose();
    }

    sampleController = standardController =
        _initSampleController = _initStandardController = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!init ||
        sampleController == null ||
        (standardVideo != null && standardController == null)) {
      return new Center(
          child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const CircularProgressIndicator(),
          new FlatButton(
              child: new Text('Stop loading'.toUpperCase()),
              onPressed: () {
                if (!finishedCalled) {
                  finishedCalled = true;
                  try {
                    widget.onFinished();
                  } catch (_) {}
                }
              }),
        ],
      ));
    }

    return buildContent(context);
  }

  Widget buildContent(BuildContext context) {
    List<Widget> widgets = <Widget>[
      new Expanded(
        child: new AspectRatio(
          aspectRatio: sampleController.value.aspectRatio,
          child: new VideoPlayer(sampleController),
        ),
      ),
    ];

    double maxProgress =
        sampleController.value.duration.inMilliseconds.toDouble();
    double currentProgress =
        sampleController.value.position.inMilliseconds.toDouble();
    currentProgress = min(maxProgress, currentProgress);

    // hijacking ListTile because Row doesn't (didn't) work here
    Widget control = new ListTile(
      leading: new IconButton(
        icon: new Icon(Icons.stop, color: Colors.white),
        onPressed: () {
          try {
            if (sampleController != null) {
              sampleController.pause().then((_) {
                sampleController.dispose();
                sampleController = null;
              }).catchError((_) {
                sampleController.dispose();
                sampleController = null;
              });
            }
            if (standardController != null) {
              standardController.pause().then((_) {
                standardController.dispose();
                standardController = null;
              }).catchError((_) {
                standardController.dispose();
                standardController = null;
              });
            }
          } catch (_) {}

          if (!finishedCalled) {
            finishedCalled = true;
            try {
              widget.onFinished();
            } catch (_) {}
          }
        },
      ),
      title: new Slider(
        max: maxProgress,
        value: currentProgress,
        onChanged: (value) {
          // TODO
        },
      ),
    );

    if (standardController != null) {
      widgets.insert(0, control);
      widgets.insert(
        0,
        new Expanded(
          child: new AspectRatio(
            aspectRatio: standardController.value.aspectRatio,
            child: new VideoPlayer(standardController),
          ),
        ),
      );
    } else {
      widgets.add(control);
    }

    return new Column(children: widgets);
  }

  bool get finished {
    if (sampleController == null) return false;

    var duration = sampleController.value.duration.inMilliseconds;
    if (standardController != null) {
      duration =
          min(duration, standardController.value.duration.inMilliseconds);
    }

    if (sampleController.value.position.inMilliseconds >= duration - 128)
      return true;
    if (standardController != null) {
      if (standardController.value.position.inMilliseconds >= duration - 128)
        return true;
    }

    return false;
  }

  void onUpdate() {
    if (!mounted) return;

    setState(() {});

    if (!finishedCalled && finished) {
      finishedCalled = true;
      try {
        widget.onFinished();
      } catch (_) {}
    }

    if (!finished && sampleController != null && standardController != null) {
      if ((sampleController.value.position.inMilliseconds -
                  standardController.value.position.inMilliseconds)
              .abs() >=
          1000) {
        if (sampleController.value.position.inMilliseconds <
            standardController.value.duration.inMilliseconds) {
          standardController.seekTo(new Duration(
              milliseconds: sampleController.value.position.inMilliseconds));
        }
      }
    }
  }
}
