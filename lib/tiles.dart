import 'package:flutter/material.dart';

class Tiles extends StatefulWidget {
  Tiles({Key key, @required this.children}) : super(key: key);

  final List<Widget> children;

  @override
  _TilesState createState() => new _TilesState();
}

class _TilesKey extends GlobalKey {
  final Key key1, key2;

  const _TilesKey(this.key1, this.key2) : super.constructor();

  @override
  bool operator ==(other) {
    if (runtimeType != other.runtimeType) return false;
    return key1 == other.key1 && key2 == other.key2;
  }

  @override
  int get hashCode => hashValues(key1, key2);
}

class _TilesState extends State<Tiles> {
  GlobalKey _key = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    List<Widget> rows = new List<Widget>();

    for (int i = 0; i < widget.children.length; i += 2) {
      List<Widget> row = new List<Widget>();

      if (widget.children[i].key != null) {
        row.add(new Expanded(
            key: new _TilesKey(_key, widget.children[i].key),
            child: widget.children[i]));
      } else {
        row.add(new Expanded(child: widget.children[i]));
      }
      if (i + 1 < widget.children.length) {
        if (widget.children[i + 1].key != null) {
          row.add(new Expanded(
              key: new _TilesKey(_key, widget.children[i + 1].key),
              child: widget.children[i + 1]));
        } else {
          row.add(new Expanded(child: widget.children[i + 1]));
        }
      } else {
        row.add(new Expanded(child: new Container()));
      }

      rows.add(
          new Row(crossAxisAlignment: CrossAxisAlignment.start, children: row));
    }

    return new Column(children: rows);
  }
}
