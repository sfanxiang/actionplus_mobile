import 'dart:async';

import 'package:flutter/material.dart';

import '../action_manager/action_manager.dart';
import '../import_page/import_page.dart';
import '../paged_tiles.dart';
import 'action_browser_item.dart';

class ActionBrowser extends StatefulWidget {
  ActionBrowser({Key key, this.bottomPadding = 0.0}) : super(key: key);

  final double bottomPadding;

  @override
  _ActionBrowserState createState() => new _ActionBrowserState();
}

class _ActionBrowserState extends State<ActionBrowser> {
  StreamSubscription _storageWriteStreamSub;
  List<String> _list;

  @override
  void initState() {
    super.initState();
    ActionManager.list().then((value) {
      if (!mounted) return;

      _list = value;
      setState(() {});
    });
    _storageWriteStreamSub = ActionManager.storageWriteStream.listen((_) {
      ActionManager.list().then((value) {
        if (!mounted) return;

        _list = value;
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _storageWriteStreamSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_list == null)
      return new Center(child: new CircularProgressIndicator());

    if (_list.isEmpty) {
      return new InkWell(
        child: new Container(
          constraints: new BoxConstraints.expand(),
          alignment: Alignment.center,
          child: new SingleChildScrollView(
              child: new SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: new Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new Icon(Icons.free_breakfast,
                            size: 56.0, color: Colors.grey),
                        new Padding(padding: EdgeInsets.only(right: 8.0)),
                        new Text('No video available.\nClick to add a video!',
                            style: new TextStyle(
                                color: Colors.grey, fontSize: 18.0)),
                      ]))),
        ),
        onTap: () {
          Navigator.push(context,
              new MaterialPageRoute(builder: (context) => new ImportPage()));
        },
      );
    }

    return new PagedTiles(
      children: _list
          .map((id) => new ActionBrowserItem(key: new Key(id), id: id))
          .toList(),
      pageSize: 8,
      bottomPadding: widget.bottomPadding,
    );
  }
}
