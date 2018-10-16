import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../actionplus_localizations.dart';

class CameraPicker extends StatefulWidget {
  CameraPicker({Key key, @required this.onPicked}) : super(key: key);

  final ValueChanged<CameraDescription> onPicked;

  @override
  _CameraPickerState createState() => new _CameraPickerState();
}

class _CameraPickerState extends State<CameraPicker> {
  bool _loading = false;
  List<CameraDescription> _cameras;
  CameraDescription _currentCamera;

  final Color _color = Colors.white;

  CameraDescription _chooseBestCamera(List<CameraDescription> cameras) {
    for (CameraDescription camera in cameras) {
      // Prefer front camera.
      if (camera.lensDirection == CameraLensDirection.front) return camera;
    }
    if (cameras.length > 0) return cameras[0];
    return null;
  }

  void _loadCameras() {
    if (_loading) return;

    _loading = true;

    availableCameras().then((List<CameraDescription> cameras) {
      _loading = false;
      _cameras = cameras;
      _currentCamera = _chooseBestCamera(_cameras);

      if (mounted) {
        setState(() {});
        widget.onPicked(_currentCamera);
      }
    }).catchError((_) {
      _loading = false;
      _cameras = [];
      _currentCamera = null;

      if (mounted) {
        setState(() {});
        widget.onPicked(_currentCamera);
      }
    });
  }

  Icon _cameraIcon(BuildContext context, CameraDescription camera,
      {bool needColor = false}) {
    if (needColor) {
      if (camera == null) {
        return new Icon(Icons.camera_alt, color: _color);
      }

      switch (camera.lensDirection) {
        case CameraLensDirection.back:
          return new Icon(Icons.camera_rear, color: _color);
        case CameraLensDirection.front:
          return new Icon(Icons.camera_front, color: _color);
        default:
          return new Icon(Icons.camera_alt, color: _color);
      }
    } else {
      if (camera == null) {
        return new Icon(Icons.camera_alt);
      }

      switch (camera.lensDirection) {
        case CameraLensDirection.back:
          return new Icon(Icons.camera_rear);
        case CameraLensDirection.front:
          return new Icon(Icons.camera_front);
        default:
          return new Icon(Icons.camera_alt);
      }
    }
  }

  Text _cameraText(BuildContext context, CameraDescription camera) {
    if (camera == null)
      return new Text(ActionplusLocalizations.of(context).cameraUnavailable);

    switch (camera.lensDirection) {
      case CameraLensDirection.back:
        return new Text(ActionplusLocalizations.of(context).backCamera);
      case CameraLensDirection.front:
        return new Text(ActionplusLocalizations.of(context).frontCamera);
      default:
        return new Text(ActionplusLocalizations.of(context).externalCamera);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameras == null) {
      _loadCameras();
      return new CircularProgressIndicator();
    } else {
      List<PopupMenuItem<CameraDescription>> items =
          _cameras.map((CameraDescription camera) {
        return new PopupMenuItem<CameraDescription>(
          value: camera,
          child: new ListTile(
            leading: _cameraIcon(context, camera),
            title: _cameraText(context, camera),
          ),
        );
      }).toList();

      if (items.isEmpty) {
        items = [
          new PopupMenuItem<CameraDescription>(
              value: null,
              child: new ListTile(
                leading: _cameraIcon(context, null),
                title: _cameraText(context, null),
                enabled: false,
              ))
        ];
      }

      return new PopupMenuButton(
          tooltip: ActionplusLocalizations.of(context).selectCamera,
          icon: _cameraIcon(context, _currentCamera, needColor: true),
          initialValue:
              _currentCamera != null && _cameras.indexOf(_currentCamera) != -1
                  ? _currentCamera
                  : null,
          itemBuilder: (BuildContext context) => items,
          onSelected: (CameraDescription result) {
            _currentCamera = result;

            if (mounted) {
              setState(() {});
              widget.onPicked(result);
            }
          });
    }
  }
}
