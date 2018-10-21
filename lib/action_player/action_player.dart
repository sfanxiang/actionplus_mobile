import 'dart:io';

import 'package:flutter/material.dart';

import '../action_manager/action_manager.dart';
import '../player/dual_player.dart';
import '../player/player.dart';
import 'action_player_initializer.dart';
import 'action_model.dart';
import 'model_painter.dart';

class ActionPlayer extends StatefulWidget {
  ActionPlayer({
    Key key,
    @required this.id,
    this.standardId,
    this.onFinish,
  }) : super(key: key);

  final String id;
  final String standardId;
  final VoidCallback onFinish;

  @override
  _ActionPlayerState createState() => new _ActionPlayerState();
}

enum SpeedOption {
  speedAuto,
  speed1_0,
  speed0_5,
}
enum MovementsOption {
  auto,
  show,
  hide,
}

class _ActionPlayerState extends State<ActionPlayer> {
  bool init = false;
  bool finished = false;
  File sampleFile, standardFile;
  ActionModelData dualModelData;
  Duration dualPosition = new Duration(milliseconds: 0);
  SpeedOption dualSpeedOption = SpeedOption.speedAuto;
  MovementsOption dualMovementsOption = MovementsOption.auto;

  @override
  void initState() {
    super.initState();

    if (widget.standardId == null) {
      ActionPlayerInitializer.initializeVideoFile(widget.id).then((file) {
        if (!mounted) return;

        sampleFile = file;
        init = true;
        setState(() {});
      });
    } else {
      ActionPlayerInitializer.initializeVideoFile2(widget.id, widget.standardId)
          .then((files) {
        if (!mounted) return;

        if (files.item2 == null) {
          sampleFile = files.item1;
          init = true;
          setState(() {});
          return;
        }

        new ActionModel(widget.id, widget.standardId).getData().then((data) {
          if (!mounted) return;

          if (data == null) {
            sampleFile = files.item1;
            init = true;
            setState(() {});
            return;
          }

          sampleFile = files.item1;
          standardFile = files.item2;
          dualModelData = data;
          init = true;
          setState(() {});
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!init) {
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
              onPressed: finish,
            )
          ],
        ),
      );
    }

    return buildContent(context);
  }

  Widget buildContent(BuildContext context) {
    if (standardFile == null) {
      return new Player(
        file: sampleFile,
        flipped: true,
        onComplete: finish,
        onStop: finish,
      );
    } else {
      final int frameLength = 1000 ~/ ActionManager.readFrameRate;
      int pos =
          ((dualPosition.inMilliseconds + frameLength - 1) ~/ frameLength);
      if (dualModelData != null)
        pos = pos.clamp(0, dualModelData.highlights.length - 1);

      return new Stack(
        children: <Widget>[
          new DualPlayer(
            sampleFile: sampleFile,
            standardFile: standardFile,
            speed: getSpeed(
                dualSpeedOption,
                dualModelData != null
                    ? (dualModelData.highlights[pos] ? 0.5 : 1.0)
                    : 1.0),
            flipped: true,
            sampleOverlay: getMovementsSwitch(dualMovementsOption,
                    dualModelData != null && dualModelData.highlights[pos])
                ? new CustomPaint(
                    painter:
                        new ModelPainter(dualModelData.standardData[pos]),
                  )
                : new Container(width: 0.0, height: 0.0),
            onComplete: finish,
            onUpdate: (value) {
              if (!mounted) return;
              dualPosition = value.position;
              setState(() {});
            },
            onStop: finish,
          ),
          new Positioned(
            right: 1.0,
            bottom: 1.0,
            child: new Column(
              children: <Widget>[
                new IconButton(
                  icon: getSpeedOptionIcon(dualSpeedOption),
                  tooltip: getSpeedOptionText(dualSpeedOption),
                  onPressed: () {
                    if (!mounted) return;
                    dualSpeedOption = SpeedOption.values[
                        (dualSpeedOption.index + 1) %
                            SpeedOption.values.length];
                    setState(() {});
                  },
                ),
                new IconButton(
                  icon: getMovementsOptionIcon(dualMovementsOption),
                  tooltip: getMovementsOptionText(dualMovementsOption),
                  onPressed: () {
                    if (!mounted) return;
                    dualMovementsOption = MovementsOption.values[
                        (dualMovementsOption.index + 1) %
                            MovementsOption.values.length];
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  void finish() {
    if (!mounted) return;
    if (finished) return;

    finished = true;
    try {
      widget.onFinish();
    } catch (_) {}
  }

  double getSpeed(SpeedOption option, double autoSpeed) {
    switch (option) {
      case SpeedOption.speedAuto:
        return autoSpeed;
      case SpeedOption.speed1_0:
        return 1.0;
      case SpeedOption.speed0_5:
        return 0.5;
    }
    return autoSpeed;
  }

  Icon getSpeedOptionIcon(SpeedOption option) {
    switch (option) {
      case SpeedOption.speedAuto:
        return new Icon(Icons.play_circle_outline, color: Colors.white);
      case SpeedOption.speed1_0:
        return new Icon(Icons.play_circle_filled, color: Colors.white);
      case SpeedOption.speed0_5:
        return new Icon(Icons.slow_motion_video, color: Colors.white);
    }
    return new Icon(Icons.play_circle_outline, color: Colors.white);
  }

  String getSpeedOptionText(SpeedOption option) {
    switch (option) {
      case SpeedOption.speedAuto:
        return "Current speed: auto";
      case SpeedOption.speed1_0:
        return "Current speed: 1.0x";
      case SpeedOption.speed0_5:
        return "Current speed: 0.5x";
    }
    return "Current speed: auto";
  }

  bool getMovementsSwitch(MovementsOption option, bool autoMovements) {
    switch (option) {
      case MovementsOption.auto:
        return autoMovements;
      case MovementsOption.show:
        return true;
      case MovementsOption.hide:
        return false;
    }
    return autoMovements;
  }

  Icon getMovementsOptionIcon(MovementsOption option) {
    switch (option) {
      case MovementsOption.auto:
        return new Icon(Icons.layers, color: Colors.white);
      case MovementsOption.show:
        return new Icon(Icons.accessibility, color: Colors.white);
      case MovementsOption.hide:
        return new Icon(Icons.block, color: Colors.white);
    }
    return new Icon(Icons.layers, color: Colors.white);
  }

  String getMovementsOptionText(MovementsOption option) {
    switch (option) {
      case MovementsOption.auto:
        return "Standard movements: auto";
      case MovementsOption.show:
        return "Standard movements: show";
      case MovementsOption.hide:
        return "Standard movements: hide";
    }
    return "Standard movements: auto";
  }
}
