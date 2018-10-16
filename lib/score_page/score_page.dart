import 'package:flutter/material.dart';

import '../action_manager/action_manager.dart';
import '../action_score_picker/action_score_picker.dart';

class ScorePage extends StatefulWidget {
  ScorePage({Key key, @required this.id}) : super(key: key);

  final String id;

  @override
  _ScorePageState createState() => new _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Score')),
      body: new Builder(builder: buildChooseTarget),
    );
  }

  Widget buildChooseTarget(BuildContext context) {
    List<Widget> widgets = new List<Widget>();

    widgets.add(new Padding(padding: const EdgeInsets.only(bottom: 8.0)));

    widgets.add(new Align(
        alignment: AlignmentDirectional.topStart,
        child: new Container(
          height: 20.0,
          padding: const EdgeInsetsDirectional.only(start: 16.0, bottom: 8.0),
          alignment: AlignmentDirectional.centerStart,
          child: Text('Choose a standard video:'),
        )));

    widgets.add(new Expanded(
      child: new ActionScorePicker(
        pickForId: widget.id,
        onPicked: (id) {
          if (!mounted) return;

          ActionManager.info(widget.id).then((info) {
            info.scoreAgainst = id;
            ActionManager.update(widget.id, info);
          });
          Navigator.of(context).pop();

          // TODO: show score and comparison
        },
      ),
    ));

    return new Column(children: widgets);
  }
}
