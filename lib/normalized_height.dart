import 'package:flutter/material.dart';

class NormalizedHeight extends StatelessWidget {
  NormalizedHeight({Key key, @required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(builder: (context, viewportConstraints) {
      return new ConstrainedBox(
          constraints: new BoxConstraints(
            minWidth: viewportConstraints.maxWidth,
            maxWidth: viewportConstraints.maxWidth,
            minHeight: viewportConstraints.maxWidth / 1.6,
            maxHeight: viewportConstraints.maxWidth * 1.6,
          ),
          child: child);
    });
  }
}
