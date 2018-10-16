import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';

import '../action_picker/action_picker.dart';
import '../action_recorder/action_recorder.dart';
import '../actionplus_localizations.dart';
import 'import_enter_once.dart';

class RecordPage extends StatefulWidget {
  RecordPage({Key key, this.onSaved}) : super(key: key);

  final VoidCallback onSaved;

  @override
  _RecordPageState createState() => new _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
          title: new Text(ActionplusLocalizations.of(context).recordVideo)),
      body: buildChoices(context),
    );
  }

  Widget buildChoices(context) {
    List<Widget> widgets = new List<Widget>();

    widgets.add(new Padding(padding: const EdgeInsets.only(bottom: 4.0)));

    widgets.add(new Align(
        alignment: Alignment.bottomRight,
        child: new FlatButton.icon(
            icon: new Icon(Icons.arrow_forward),
            label: new Text('Skip this and record'.toUpperCase()),
            textColor: Theme.of(context).primaryColor,
            onPressed: () => onSelected(null))));

    widgets.add(new Align(
        alignment: AlignmentDirectional.topStart,
        child: new Container(
          height: 24.0,
          padding: const EdgeInsetsDirectional.only(start: 16.0, bottom: 24.0),
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'Select a standard video (optional):',
            style: Theme.of(context).textTheme.body1.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
          ),
        )));

    widgets.add(new Expanded(
      child: new ActionPicker(
        onPicked: onSelected,
      ),
    ));

    return new Column(children: widgets);
  }

  void onSelected(String id) {
    if (!mounted) return;

    if (selected) return;
    selected = true;

    if (ImportEnterOnce.importing) return;
    ImportEnterOnce.importing = true;

    bool finished = false;
    try {
      SystemChrome.setEnabledSystemUIOverlays([]);
    } catch (_) {}
    try {
      Screen.keepOn(true);
    } catch (_) {}

    Navigator.pushReplacement(
      context,
      new MaterialPageRoute(
        builder: (context) => new WillPopScope(
              child: new Material(
                color: Colors.black,
                child: new ActionRecorder(
                  standardId: id,
                  onFinished: (bool saved) {
                    finished = true;

                    Navigator.maybePop(context);

                    if (!mounted) return;

                    if (saved) {
                      try {
                        widget.onSaved();
                      } catch (_) {}
                    }
                  },
                ),
              ),
              onWillPop: () async {
                if (!finished) return false;

                ImportEnterOnce.importing = false;

                try {
                  SystemChrome.setEnabledSystemUIOverlays(
                      SystemUiOverlay.values);
                } catch (_) {}
                try {
                  Screen.keepOn(false);
                } catch (_) {}

                return true;
              },
            ),
      ),
    );
  }
}
