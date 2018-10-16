import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';

import '../action_manager/action_manager.dart';
import '../action_manager/action_metadata.dart';
import '../action_player/action_player.dart';
import '../critical_enter_once.dart';
import '../normalized_height.dart';
import '../reduced_serialized_entrance.dart';
import 'action_browser_actions.dart';

class ActionBrowserItem extends StatefulWidget {
  ActionBrowserItem({Key key, @required this.id}) : super(key: key);

  final String id;

  @override
  _ActionBrowserItemState createState() => new _ActionBrowserItemState();
}

class _ActionBrowserItemState extends State<ActionBrowserItem> {
  ActionMetadata _metadata;

  StreamSubscription _storageWriteStreamSub;

  String _thumbnail;

  ReducedSerializedEntrance updateCaller;

  @override
  void initState() {
    super.initState();

    updateCaller = new ReducedSerializedEntrance(_update);
    updateCaller.call();

    _storageWriteStreamSub = ActionManager.storageWriteStream.listen((e) {
      updateCaller.call();
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

  Future<Null> _update() async {
    var info = await ActionManager.info(widget.id);
    if (!mounted) return;

    _metadata = info;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return new Card(
      child: new Column(children: <Widget>[
        new Align(
          alignment: AlignmentDirectional.topCenter,
          child: _thumbnail == null
              ? new CircularProgressIndicator()
              : buildPreview(context),
        ),
        new Align(
            alignment: AlignmentDirectional.bottomStart,
            child: new SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: getTitleText(context))),
        new Align(
          alignment: AlignmentDirectional.bottomStart,
          child: new ActionBrowserActions(id: widget.id),
        )
      ]),
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

  Widget buildPreview(BuildContext context) {
    return new InkWell(
      child: new Stack(
        children: <Widget>[
          new NormalizedHeight(
            child: Image.file(new File(_thumbnail), fit: BoxFit.fill),
          ),
          new Positioned(
            left: 0.0,
            bottom: 0.0,
            child: new Icon(Icons.play_circle_filled),
          ),
        ],
      ),
      onTap: () {
        if (!mounted) return;
        if (_metadata == null) return;

        if (CriticalEnterOnce.entered) return;
        CriticalEnterOnce.entered = true;

        try {
          SystemChrome.setEnabledSystemUIOverlays([]);
        } catch (_) {}
        try {
          Screen.keepOn(true);
        } catch (_) {}

        Navigator.push(
          context,
          new MaterialPageRoute(
            builder: (context) => new WillPopScope(
                  child: new Material(
                    child: new ActionPlayer(
                      id: widget.id,
                      standardId: _metadata.scoreAgainst != ''
                          ? _metadata.scoreAgainst
                          : null,
                      onFinished: () {
                        CriticalEnterOnce.entered = false;

                        if (mounted) {
                          Navigator.pop(context);
                        }

                        try {
                          SystemChrome.setEnabledSystemUIOverlays(
                              SystemUiOverlay.values);
                        } catch (_) {}
                        try {
                          Screen.keepOn(false);
                        } catch (_) {}
                      },
                    ),
                  ),
                  onWillPop: () async => false,
                ),
          ),
        );
      },
    );
  }
}
