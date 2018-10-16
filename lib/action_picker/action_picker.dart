import 'dart:async';

import 'package:flutter/material.dart';

import '../action_manager/action_manager.dart';
import '../paged_tiles.dart';
import 'action_picker_item.dart';

class ActionPicker extends StatefulWidget {
  ActionPicker({
    Key key,
    @required this.onPicked,
    Set<String> excludeIds,
    this.emptyText,
  })  : this.excludeIds = excludeIds ?? new Set<String>(),
        super(key: key);

  final ValueChanged<String> onPicked;
  final Set<String> excludeIds;
  final String emptyText;

  @override
  _ActionPickerState createState() => new _ActionPickerState();
}

class _ActionPickerState extends State<ActionPicker> {
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

    List widgetList = _list
        .where((id) => !widget.excludeIds.contains(id))
        .map((id) => new ActionPickerItem(
            key: new Key(id),
            id: id,
            onPressed: () {
              widget.onPicked(id);
            }))
        .toList();

    if (widgetList.isEmpty) {
      return new SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: new Row(children: <Widget>[
            new Icon(Icons.free_breakfast, size: 56.0, color: Colors.grey),
            new Padding(padding: EdgeInsets.only(right: 8.0)),
            new Text(
                widget.emptyText == null
                    ? 'No video available.'
                    : widget.emptyText,
                style: new TextStyle(color: Colors.grey, fontSize: 18.0)),
          ]));
    }

    return new PagedTiles(
      children: widgetList,
      pageSize: 8,
      bottomSelector: true,
    );
  }
}
