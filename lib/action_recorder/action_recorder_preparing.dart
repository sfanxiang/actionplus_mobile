import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../action_preview/action_preview.dart';
import '../actionplus_localizations.dart';
import 'camera_config.dart';

class ActionRecorderPreparing extends StatefulWidget {
  // note: never unmount this widget before onFinished is called!
  ActionRecorderPreparing({Key key, @required this.onFinished, this.standardId})
      : super(key: key);

  final ValueChanged<CameraController> onFinished;
  final String standardId;

  @override
  _ActionRecorderPreparingState createState() =>
      new _ActionRecorderPreparingState();
}

class _ActionRecorderPreparingState extends State<ActionRecorderPreparing> {
  UniqueKey _cameraConfigKey = new UniqueKey();

  CameraController _controller;
  bool _finished = false;

  void _disposeController(CameraController controller) {
    if (controller != null) controller.dispose();
  }

  void _updateController(CameraController newController) {
    _controller = newController;
    if (mounted) setState(() {});
  }

  void _finish() {
    CameraController controller = _controller;

    _controller = null;

    if (mounted) {
      setState(() {});
    } else {
      _disposeController(controller);
      return;
    }

    if (_finished) {
      _disposeController(controller);
      return;
    }

    _finished = true;
    setState(() {});

    widget.onFinished(controller);
  }

  Widget buildRecorder(BuildContext context) {
    return new Stack(children: <Widget>[
      new Align(
          alignment: AlignmentDirectional.center,
          child: _controller == null
              ? new Center(child: new CircularProgressIndicator())
              : new AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: new CameraPreview(_controller))),
      new Align(
          alignment: AlignmentDirectional.topEnd,
          child: new SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _finished
                ? new Text('')
                : new CameraConfig(
                    key: _cameraConfigKey,
                    onConfigured: (controller) {
                      if (!mounted || _finished) {
                        _disposeController(controller);
                        return;
                      }

                      _updateController(controller);
                    }),
          )),
      new Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: new Container(
              margin: EdgeInsets.only(bottom: 8.0),
              child: new FloatingActionButton.extended(
                  backgroundColor: (_controller == null || _finished)
                      ? Colors.grey
                      : Colors.deepOrange,
                  icon:
                      new Icon(Icons.fiber_manual_record, color: Colors.white),
                  label: new Text(ActionplusLocalizations.of(context).record),
                  onPressed: (_controller == null || _finished)
                      ? null
                      : () {
                          if (_controller != null) _finish();
                        }))),
      new Align(
          alignment: AlignmentDirectional.bottomStart,
          child: new Container(
              margin: EdgeInsetsDirectional.only(bottom: 8.0, start: 8.0),
              child: new IconButton(
                icon: new Icon(Icons.navigate_before, color: Colors.white),
                onPressed: _finished
                    ? null
                    : () {
                        _disposeController(_controller);
                        _controller = null;

                        _finish();
                      },
              ))),
    ]);
  }

  Widget buildStandard(BuildContext context) {
    if (widget.standardId == null || widget.standardId == '')
      return new Container();
    if (_controller == null) return new CircularProgressIndicator();

    if (_controller.description.lensDirection == CameraLensDirection.front ||
        _controller.description.lensDirection == CameraLensDirection.external) {
      return new Transform(
        alignment: Alignment.center,
        transform: new Matrix4.rotationY(pi),
        child: new ActionPreview(id: widget.standardId),
      );
    } else {
      return new ActionPreview(id: widget.standardId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.standardId == null || widget.standardId == '') {
      return buildRecorder(context);
    } else {
      return new Column(
        children: <Widget>[
          new Expanded(child: new Center(child: buildStandard(context))),
          new LinearProgressIndicator(value: 0.0),
          new Expanded(child: new Center(child: buildRecorder(context))),
        ],
      );
    }
  }
}
