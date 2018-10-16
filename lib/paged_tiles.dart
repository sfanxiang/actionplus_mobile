import 'package:flutter/material.dart';

import 'pages.dart';
import 'tiles.dart';

class PagedTiles extends StatelessWidget {
  PagedTiles({
    @required this.children,
    @required this.pageSize,
    this.bottomSelector = false,
    this.bottomPadding = 0.0,
  });

  final List<Widget> children;
  final int pageSize;
  final bool bottomSelector;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = new List<Widget>();

    for (int i = 0; i < children.length; i += pageSize) {
      widgets.add(new SingleChildScrollView(
        child: new Column(children: <Widget>[
          new Tiles(
              children: children.sublist(
                  i, (i + pageSize).clamp(0, children.length))),
          new Padding(padding: EdgeInsets.only(bottom: bottomPadding)),
        ]),
      ));
    }

    return new Pages(children: widgets, bottomSelector: bottomSelector);
  }
}
