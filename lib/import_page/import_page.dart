import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../action_manager/action_manager.dart';
import '../action_manager/action_metadata.dart';
import '../actionplus_localizations.dart';
import 'import_enter_once.dart';
import 'record_page.dart';

class ImportPage extends StatefulWidget {
  ImportPage({Key key}) : super(key: key);

  @override
  _ImportPageState createState() => new _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
            title: new Text(ActionplusLocalizations.of(context).addVideos)),
        body: new Center(
            child: new SingleChildScrollView(
                child: new Column(children: <Widget>[
          new Builder(builder: buildChoices),
        ]))));
  }

  Widget buildChoices(BuildContext context) {
    return new Row(
      children: <Widget>[
        new Expanded(
            child: new Card(
          color: new Color(0xff228888),
          child: new InkWell(
            child: new Container(
                padding: EdgeInsets.all(16.0),
                child: new Column(
                  children: <Widget>[
                    new Icon(Icons.library_add,
                        size: 50.0, color: Colors.white),
                    new SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: new Text(
                            ActionplusLocalizations.of(context).importFromDevice,
                            style:
                                TextStyle(color: Colors.white, fontSize: 15.0),
                            softWrap: false)),
                  ],
                )),
            onTap: () => onImportFromDevice(context),
          ),
        )),
        new Expanded(
            child: new Card(
          color: Colors.purple,
          child: new InkWell(
            child: new Container(
                padding: EdgeInsets.all(16.0),
                child: new Column(
                  children: <Widget>[
                    new Icon(Icons.add_a_photo,
                        size: 50.0, color: Colors.white),
                    new SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: new Text(
                            ActionplusLocalizations.of(context).recordVideo,
                            style:
                                TextStyle(color: Colors.white, fontSize: 15.0),
                            softWrap: false)),
                  ],
                )),
            onTap: () => onRecordVideo(context),
          ),
        )),
      ],
    );
  }

  void onImportFromDevice(BuildContext context) {
    if (!mounted) return;

    if (ImportEnterOnce.importing) return;
    ImportEnterOnce.importing = true;

    ImagePicker.pickVideo(source: ImageSource.gallery).then((file) {
      if (!mounted) return;

      ImportEnterOnce.importing = false;

      if (file != null) {
        ActionManager.importAction(file.path, new ActionMetadata());

        Scaffold.of(context).showSnackBar(new SnackBar(
            content: new Text('Importing video...'),
            duration: new Duration(seconds: 1)));
      }
    });
  }

  void onRecordVideo(BuildContext context) {
    if (!mounted) return;

    Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => new RecordPage(
              onSaved: () {
                if (!mounted) return;

                Scaffold.of(context).showSnackBar(new SnackBar(
                    content: new Text('Saving recording...'),
                    duration: new Duration(seconds: 1)));
              },
            ),
      ),
    );
  }
}
