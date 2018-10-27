import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'action_browser/action_browser.dart';
import 'action_manager/action_manager.dart';
import 'actionplus_localizations.dart';
import 'import_page/import_page.dart';

void main() {
  runApp(new ActionplusApp());
}

class ActionplusApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Action+',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new ActionplusHomePage(title: 'Action+'),
      localizationsDelegates: [
        const ActionplusLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        // New locales should be added here.
        const Locale('en', 'US'),
      ],
    );
  }
}

class ActionplusHomePage extends StatefulWidget {
  ActionplusHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ActionplusHomePageState createState() => new _ActionplusHomePageState();
}

class _ActionplusHomePageState extends State<ActionplusHomePage> {
  bool _actionManagerInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_actionManagerInitialized) {
      new Future(() {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
            .then((_) {
          ActionManager.init().then((_) {
            if (!mounted) return;

            _actionManagerInitialized = true;
            setState(() {});
          });
        });
      });
    }

    return new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: !_actionManagerInitialized
            ? new Center(child: new CircularProgressIndicator())
            : new Builder(builder: buildActionView),
        floatingActionButton: new FloatingActionButton(
            onPressed: () {
              Navigator.push(
                  context,
                  new MaterialPageRoute(
                      builder: (context) => new ImportPage()));
            },
            child: new Icon(Icons.add)));
  }

  Widget buildActionView(BuildContext context) {
    return new ActionBrowser(bottomPadding: 56.0);
  }
}
