import 'package:flutter/material.dart';

import '../action_manager/action_manager.dart';
import '../action_score_picker/action_score_picker.dart';

class AnalyzePage extends StatefulWidget {
  AnalyzePage({Key key, @required this.id}) : super(key: key);

  final String id;

  @override
  _AnalyzePageState createState() => new _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Analyze')),
      body: new Builder(builder: buildChooseTarget),
    );
  }

  Widget buildChooseTarget(BuildContext context) {
    List<Widget> widgets = new List<Widget>();

    widgets.add(new Padding(padding: const EdgeInsets.only(bottom: 4.0)));

    widgets.add(new Align(
        alignment: Alignment.bottomRight,
        child: new FlatButton.icon(
            icon: new Icon(Icons.arrow_forward),
            label: new Text('Skip this and analyze'.toUpperCase()),
            textColor: Theme.of(context).primaryColor,
            onPressed: () {
              if (!mounted) return;

              ActionManager.analyze(widget.id);
              Navigator.of(context).pop();
            })));

    widgets.add(new Align(
        alignment: AlignmentDirectional.topStart,
        child: new Container(
          height: 24.0,
          padding: const EdgeInsetsDirectional.only(start: 16.0, bottom: 24.0),
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'Score against a standard video (optional):',
            style: Theme.of(context).textTheme.body1.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
          ),
        )));

    widgets.add(new Expanded(
      child: new ActionScorePicker(
        pickForId: widget.id,
        onPicked: (id) {
          if (!mounted) return;

          ActionManager.info(widget.id).then((info) {
            info.scoreAgainst = id;
            ActionManager.update(widget.id, info).then((_) {
              ActionManager.analyze(widget.id);
            });
          });
          Navigator.of(context).pop();

          // TODO: analyze and score
        },
      ),
    ));

    return new Column(children: widgets);
  }
}
