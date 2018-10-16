import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../action_manager/action_manager.dart';
import '../action_manager/action_metadata.dart';
import '../normalized_height.dart';

class ActionPickerItem extends StatefulWidget {
  ActionPickerItem({Key key, @required this.id, @required this.onPressed})
      : super(key: key);

  final String id;
  final VoidCallback onPressed;

  @override
  _ActionPickerItemState createState() => new _ActionPickerItemState();
}

class _ActionPickerItemState extends State<ActionPickerItem> {
  ActionMetadata _metadata;

  StreamSubscription _storageWriteStreamSub;

  String _thumbnail;

  @override
  void initState() {
    super.initState();

    updateMetadata();

    _storageWriteStreamSub = ActionManager.storageWriteStream.listen((e) {
      updateMetadata();
    });

    ActionManager.thumbnail(widget.id).then((thumbnail) {
      if (!mounted) return;

      _thumbnail = thumbnail;
      setState(() {});
    });
  }

  @override
  void dispose() {
    try {
      _storageWriteStreamSub.cancel();
    } catch (e) {}

    super.dispose();
  }

  void updateMetadata() {
    ActionManager.info(widget.id).then((result) {
      if (!mounted) return;

      _metadata = result;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Card(
      child: new InkWell(
        onTap: () {
          widget.onPressed();
        },
        child: new Column(children: <Widget>[
          new Align(
              alignment: AlignmentDirectional.topCenter,
              child: _thumbnail == null
                  ? new CircularProgressIndicator()
                  : new NormalizedHeight(
                      child:
                          Image.file(new File(_thumbnail), fit: BoxFit.fill))),
          new Align(
              alignment: AlignmentDirectional.bottomStart,
              child: new SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: getTitleText(context))),
        ]),
      ),
    );
  }

  Widget getTitleText(BuildContext context) {
    if (_metadata == null) return new Text('');
    return _metadata.title != ''
        ? new Text(_metadata.title)
        : new Text('Untitled',
            style:
                new TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
  }
}
