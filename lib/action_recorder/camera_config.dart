import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'camera_picker.dart';
import 'camera_resolution_picker.dart';

class CameraConfig extends StatefulWidget {
  CameraConfig({Key key, @required this.onConfigured}) : super(key: key);

  final ValueChanged<CameraController> onConfigured;

  @override
  _CameraConfigState createState() => new _CameraConfigState();
}

class _CameraConfigState extends State<CameraConfig> {
  UniqueKey _cameraPickerKey = new UniqueKey();
  UniqueKey _cameraResolutionPickerKey = new UniqueKey();

  bool loading = false;

  CameraDescription _currentDescription;
  ResolutionPreset _currentResolution;

  CameraController _lastCameraController;

  void _load() async {
    if (loading) return;
    if (_currentDescription == null || _currentResolution == null) return;
    if (!mounted) return;

    loading = true;

    // A lot of platforms do not support multiple camera instances.
    if (_lastCameraController != null) {
      try {
        widget.onConfigured(null);
      } catch (e) {}

      try {
        await _lastCameraController.dispose();
      } catch (e) {}

      _lastCameraController = null;

      if (!mounted) return;
    }

    CameraController cameraController =
        new CameraController(_currentDescription, _currentResolution);

    try {
      await cameraController.initialize();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => new AlertDialog(
                title: new Text('Failed to initialize camera'),
                content: new Text('Please go back and try again.'),
                actions: <Widget>[
                  new FlatButton(
                    child: new Text('OK'.toUpperCase()),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                  )
                ],
              ),
        );
      }
      return;
    }

    if (!mounted) {
      await cameraController.dispose();
      return;
    }

    _lastCameraController = cameraController;

    loading = false;

    try {
      widget.onConfigured(cameraController);
    } catch (_) {}

    if (cameraController.description != _currentDescription ||
        cameraController.resolutionPreset != _currentResolution) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
        decoration: new ShapeDecoration(
            shape: new StadiumBorder(), color: Colors.lightBlue.withAlpha(192)),
        child: new Row(
          children: <Widget>[
            new CameraPicker(
                key: _cameraPickerKey,
                onPicked: (description) {
                  _currentDescription = description;
                  _load();
                }),
            new CameraResolutionPicker(
                key: _cameraResolutionPickerKey,
                onPicked: (resolution) {
                  _currentResolution = resolution;
                  _load();
                }),
          ],
        ));
  }
}
