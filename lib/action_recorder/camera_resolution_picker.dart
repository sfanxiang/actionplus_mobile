import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../actionplus_localizations.dart';

class CameraResolutionPicker extends StatefulWidget {
  CameraResolutionPicker({Key key, @required this.onPicked}) : super(key: key);

  final ValueChanged<ResolutionPreset> onPicked;

  @override
  _CameraResolutionPickerState createState() =>
      new _CameraResolutionPickerState();
}

class _CameraResolutionPickerState extends State<CameraResolutionPicker> {
  ResolutionPreset _currentResolution;

  final Color _color = Colors.white;

  Icon _resolutionIcon(BuildContext context, ResolutionPreset resolution,
      {bool needColor = false}) {
    if (needColor) {
      switch (resolution) {
        case ResolutionPreset.high:
          return new Icon(Icons.photo_size_select_actual, color: _color);
        case ResolutionPreset.medium:
          return new Icon(Icons.photo_size_select_large, color: _color);
        case ResolutionPreset.low:
          return new Icon(Icons.photo_size_select_small, color: _color);
        default:
          return new Icon(Icons.photo_size_select_small, color: _color);
      }
    } else {
      switch (resolution) {
        case ResolutionPreset.high:
          return new Icon(Icons.photo_size_select_actual);
        case ResolutionPreset.medium:
          return new Icon(Icons.photo_size_select_large);
        case ResolutionPreset.low:
          return new Icon(Icons.photo_size_select_small);
        default:
          return new Icon(Icons.photo_size_select_small);
      }
    }
  }

  Text _resolutionText(BuildContext context, ResolutionPreset resolution) {
    switch (resolution) {
      case ResolutionPreset.high:
        return new Text(ActionplusLocalizations.of(context).highResolution);
      case ResolutionPreset.medium:
        return new Text(ActionplusLocalizations.of(context).mediumResolution);
      case ResolutionPreset.low:
        return new Text(ActionplusLocalizations.of(context).lowResolution);
      default:
        return new Text(ActionplusLocalizations.of(context).lowResolution);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentResolution == null) {
      _currentResolution = ResolutionPreset.high;

      try {
        widget.onPicked(_currentResolution);
      } catch (e) {}
    }

    List<PopupMenuItem<ResolutionPreset>> items = [
      ResolutionPreset.high,
      ResolutionPreset.medium,
      ResolutionPreset.low,
    ].map((ResolutionPreset resolution) {
      return new PopupMenuItem<ResolutionPreset>(
          value: resolution,
          child: new ListTile(
            leading: _resolutionIcon(context, resolution),
            title: _resolutionText(context, resolution),
          ));
    }).toList();

    return new PopupMenuButton<ResolutionPreset>(
      tooltip: ActionplusLocalizations.of(context).selectResolution,
      icon: _resolutionIcon(context, _currentResolution, needColor: true),
      initialValue: _currentResolution,
      itemBuilder: (context) => items,
      onSelected: ((ResolutionPreset result) {
        _currentResolution = result;

        if (mounted) {
          setState(() {});
          widget.onPicked(result);
        }
      }),
    );
  }
}
