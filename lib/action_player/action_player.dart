import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../action_manager/action_manager.dart';
import '../video_player_plus.dart';

// TODO: Some Android devices doesn't support playing two videos at the same time.
//       In the long run, offer a setting to turn off dual playback.

typedef ActionPlayerOverlayCallback = Widget Function(Duration position);
typedef ActionPlayerSpeedCallback = double Function(Duration position);

class ActionPlayer extends StatefulWidget {
  ActionPlayer({
    Key key,
    @required this.id,
    this.standardId,
    this.onFinished,
    this.sampleOverlayCallback,
    this.standardOverlayCallback,
    this.speedCallback,
  }) : super(key: key);

  final String id;
  final String standardId;
  final VoidCallback onFinished;
  final ActionPlayerOverlayCallback sampleOverlayCallback;
  final ActionPlayerOverlayCallback standardOverlayCallback;
  final ActionPlayerSpeedCallback speedCallback;

  @override
  _ActionPlayerState createState() => new _ActionPlayerState();
}

class _ActionPlayerState extends State<ActionPlayer> {
  bool init = false;
  bool finishedCalled = false;

  String sampleVideo, standardVideo;

  VideoPlayerPlusValue sampleVideoValue, standardVideoValue;

  Duration sampleSetPosition, standardSetPosition;
  bool paused = false;

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
          finishedCalled = true;
          try {
            widget.onFinished();
          } catch (_) {}
        }
        return;
      }

      init = true;
      if (mounted) setState(() {});
    }();
  }

  @override
  Widget build(BuildContext context) {
    if (!init) {
      return new Center(
          child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const CircularProgressIndicator(),
          new FlatButton(
              child: new Text(
                'Stop loading'.toUpperCase(),
                style: new TextStyle(color: Colors.white),
              ),
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
    Duration currentSampleSetPosition = sampleSetPosition;
    sampleSetPosition = null;
    Duration currentStandardSetPosition = standardSetPosition;
    standardSetPosition = null;

    var speed = 0.0;

    if (!paused) {
      if (sampleVideoValue != null && widget.speedCallback != null) {
        speed = max(0.4, widget.speedCallback(sampleVideoValue.position));
      } else {
        speed = 1.0;
      }
    }

    List<Widget> widgets = <Widget>[
      new Expanded(
        child: new Stack(
          children: <Widget>[
            new VideoPlayerPlus(
              file: new File(sampleVideo),
              position: currentSampleSetPosition,
              volume: standardVideo != null ? 0.0 : 1.0,
              speed: speed,
              onUpdated: onSampleUpdated,
              onCompleted: onCompleted,
            ),
            sampleVideoValue != null && widget.sampleOverlayCallback != null
                ? new Positioned.fill(
                    child:
                        widget.sampleOverlayCallback(sampleVideoValue.position))
                : new Container(height: 0.0, width: 0.0),
          ],
        ),
      ),
    ];

    double maxProgress =
        sampleVideoValue?.duration?.inMilliseconds?.toDouble() ?? 1.0;
    if (standardVideo != null) {
      maxProgress = min(maxProgress,
          standardVideoValue?.duration?.inMilliseconds?.toDouble() ?? 1.0);
    }
    double currentProgress =
        sampleVideoValue?.position?.inMilliseconds?.toDouble() ?? 0.0;
    currentProgress = min(maxProgress, currentProgress);

    // hijacking ListTile because Row doesn't (didn't) work here
    Widget control = new ListTile(
      leading: new IconButton(
        icon: new Icon(paused ? Icons.play_arrow : Icons.pause,
            color: Colors.white),
        onPressed: () {
          if (!mounted) return;

          paused = !paused;
          setState(() {});
        },
      ),
      title: new ListTile(
        contentPadding: EdgeInsets.all(0.0),
        leading: new IconButton(
          icon: new Icon(Icons.stop, color: Colors.white),
          onPressed: () {
            if (!mounted) return;

            paused = true;
            if (!finishedCalled) {
              finishedCalled = true;
              try {
                widget.onFinished();
              } catch (_) {}
            }
            setState(() {});
          },
        ),
        title: new Slider(
          max: maxProgress,
          value: currentProgress,
          onChanged: (value) {
            if (!mounted) return;

            int truncated = value.truncate();
            if (truncated < maxProgress) {
              sampleSetPosition =
                  standardSetPosition = new Duration(milliseconds: truncated);
              setState(() {});
            }
          },
        ),
      ),
    );

    if (standardVideo != null) {
      widgets.insert(0, control);
      widgets.insert(
        0,
        new Expanded(
          child: new Stack(
            children: <Widget>[
              new VideoPlayerPlus(
                file: new File(standardVideo),
                position: currentStandardSetPosition,
                speed: speed,
                onUpdated: onStandardUpdated,
                onCompleted: onCompleted,
              ),
              sampleVideoValue != null && // use sample video's value here
                      widget.standardOverlayCallback != null
                  ? new Positioned.fill(
                      child: widget
                          .standardOverlayCallback(sampleVideoValue.position))
                  : new Container(height: 0.0, width: 0.0),
            ],
          ),
        ),
      );
    } else {
      widgets.add(control);
    }

    return new Column(children: widgets);
  }

  void onSampleUpdated(VideoPlayerPlusValue value) {
    if (!mounted) return;

    sampleVideoValue = value;
    setState(() {});
  }

  void onStandardUpdated(VideoPlayerPlusValue value) {
    if (!mounted) return;

    standardVideoValue = value;
    if (sampleVideoValue != null) {
      if ((sampleVideoValue.position.inMilliseconds -
                      standardVideoValue.position.inMilliseconds)
                  .abs() >=
              200 &&
          standardSetPosition == null) {
        standardSetPosition = sampleVideoValue.position;
      }
    }
    setState(() {});
  }

  void onCompleted() {
    if (!mounted) return;

    paused = true;
    if (!finishedCalled) {
      finishedCalled = true;
      try {
        widget.onFinished();
      } catch (_) {}
    }
    setState(() {});
  }
}
