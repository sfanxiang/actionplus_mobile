import 'dart:io';

import 'package:flutter/material.dart';

import '../action_manager/action_manager.dart';

class ActionPreview extends StatefulWidget {
  // note: never unmount this widget before onFinished is called!
  ActionPreview({Key key, @required this.id}) : super(key: key);

  final String id;

  @override
  _ActionPreviewState createState() => new _ActionPreviewState();
}

class _ActionPreviewState extends State<ActionPreview> {
  File file;

  @override
  void initState() {
    ActionManager.thumbnail(widget.id).then((filePath) {
      if (!mounted) return;

      file = new File(filePath);
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return new CircularProgressIndicator();
    } else {
      return new Image.file(file);
    }
  }
}
