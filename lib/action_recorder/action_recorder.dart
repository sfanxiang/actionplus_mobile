import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../action_manager/action_manager.dart';
import '../action_manager/action_metadata.dart';
import 'action_recorder_preparing.dart';
import 'action_recorder_recording.dart';

class ActionRecorder extends StatefulWidget {
  // note: never unmount this widget before onFinished is called!
  ActionRecorder({Key key, this.onFinished, this.standardId}) : super(key: key);

  final ValueChanged<bool> onFinished;
  final String standardId;

  @override
  _ActionRecorderState createState() => new _ActionRecorderState();
}

enum _ActionRecorderStage {
  preparing,
  recording,
  finished,
}

class _ActionRecorderState extends State<ActionRecorder> {
  _ActionRecorderStage _currentStage = _ActionRecorderStage.preparing;
  CameraController _cameraController;

  void _setStage(
      {@required _ActionRecorderStage stage,
      @required _ActionRecorderStage expectedCurrentStage,
      @required bool saved}) {
    if (_currentStage == _ActionRecorderStage.finished || !mounted) return;
    if (_currentStage != expectedCurrentStage) return;

    _currentStage = stage;
    setState(() {});

    if (stage == _ActionRecorderStage.finished) {
      if (widget.onFinished != null) widget.onFinished(saved);
    }
  }

  Widget _buildCurrentStage(BuildContext context) {
    switch (_currentStage) {
      case _ActionRecorderStage.preparing:
        return new ActionRecorderPreparing(
          standardId: widget.standardId,
          onFinished: (cameraController) {
            if (!mounted) return;

            if (cameraController != null) {
              if (_currentStage == _ActionRecorderStage.preparing && mounted)
                setState(() => _cameraController = cameraController);
              _setStage(
                  stage: _ActionRecorderStage.recording,
                  expectedCurrentStage: _ActionRecorderStage.preparing,
                  saved: false);
            } else {
              _setStage(
                  stage: _ActionRecorderStage.finished,
                  expectedCurrentStage: _ActionRecorderStage.preparing,
                  saved: false);
            }
          },
        );
      case _ActionRecorderStage.recording:
        return new ActionRecorderRecording(
          standardId: widget.standardId,
          cameraController: _cameraController,
          onFinished: (result) {
            try {
              _cameraController.dispose();
            } catch (_) {}

            if (result.saved) {
              ActionManager.importAction(result.path,
                  new ActionMetadata()..scoreAgainst = widget.standardId ?? '',
                  move: true);
            }

            _setStage(
              stage: _ActionRecorderStage.finished,
              expectedCurrentStage: _ActionRecorderStage.recording,
              saved: result.saved,
            );
          },
        );
      default: // finished
        return new Center(child: new CircularProgressIndicator());
    }
  }

  @override
  Widget build(BuildContext context) {
    return new AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: new Container(
        constraints: BoxConstraints.expand(),
        child: _buildCurrentStage(context),
      ),
    );
  }
}
