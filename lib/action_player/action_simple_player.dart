import 'dart:io';

import 'package:flutter/material.dart';

import '../player/dual_player.dart';
import '../player/player.dart';
import 'action_player_initializer.dart';

class ActionSimplePlayer extends StatefulWidget {
  ActionSimplePlayer({
    Key key,
    @required this.id,
    this.standardId,
    this.onFinish,
  }) : super(key: key);

  final String id;
  final String standardId;
  final VoidCallback onFinish;

  @override
  _ActionSimplePlayerState createState() => new _ActionSimplePlayerState();
}

class _ActionSimplePlayerState extends State<ActionSimplePlayer> {
  bool init = false;
  bool finished = false;
  File sampleFile, standardFile;

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

        sampleFile = files.item1;
        standardFile = files.item2;
        init = true;
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!init) {
      return new Center(
        child: new Column(
          children: <Widget>[
            new CircularProgressIndicator(),
            new FlatButton(
              child: new Text('Stop loading'.toUpperCase()),
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
        onComplete: finish,
        onStop: finish,
      );
    } else {
      return new DualPlayer(
        sampleFile: sampleFile,
        standardFile: standardFile,
        onComplete: finish,
        onStop: finish,
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
}
