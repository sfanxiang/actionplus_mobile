import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n/messages_all.dart';

class ActionplusLocalizations {
  static Future<ActionplusLocalizations> load(Locale locale) {
    final String name =
        locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      return ActionplusLocalizations();
    });
  }

  static ActionplusLocalizations of(BuildContext context) {
    return Localizations.of<ActionplusLocalizations>(
        context, ActionplusLocalizations);
  }

  String get addVideoClips {
    return Intl.message(
      'Add video clips',
      name: 'addVideoClips',
      desc: 'Add video clips',
    );
  }

  String get importFromDevice {
    return Intl.message(
      'Import from device',
      name: 'importFromDevice',
      desc: 'Import from device',
    );
  }

  String get recordVideo {
    return Intl.message(
      'Record a video',
      name: 'recordVideo',
      desc: 'Record a video',
    );
  }

  String get selectCamera {
    return Intl.message(
      'Select camera',
      name: 'selectCamera',
      desc: 'Select camera',
    );
  }

  String get backCamera {
    return Intl.message(
      'Back camera',
      name: 'backCamera',
      desc: 'Back camera',
    );
  }

  String get frontCamera {
    return Intl.message(
      'Front camera',
      name: 'frontCamera',
      desc: 'Front camera',
    );
  }

  String get externalCamera {
    return Intl.message(
      'External camera',
      name: 'externalCamera',
      desc: 'External camera',
    );
  }

  String get cameraUnavailable {
    return Intl.message(
      'Camera unavailable',
      name: 'cameraUnavailable',
      desc: 'Camera unavailable',
    );
  }

  String get selectResolution {
    return Intl.message(
      'Select resolution',
      name: 'selectResolution',
      desc: 'Select resolution',
    );
  }

  String get highResolution {
    return Intl.message(
      'High resolution',
      name: 'highResolution',
      desc: 'High resolution',
    );
  }

  String get mediumResolution {
    return Intl.message(
      'Medium resolution',
      name: 'mediumResolution',
      desc: 'Medium resolution',
    );
  }

  String get lowResolution {
    return Intl.message(
      'Low resolution',
      name: 'lowResolution',
      desc: 'Low resolution',
    );
  }

  String get record {
    return Intl.message(
      'Record',
      name: 'record',
      desc: 'Record',
    );
  }

  String get go {
    return Intl.message(
      'Go',
      name: 'go',
      desc: 'Go',
    );
  }
}

class ActionplusLocalizationsDelegate
    extends LocalizationsDelegate<ActionplusLocalizations> {
  const ActionplusLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<ActionplusLocalizations> load(Locale locale) =>
      ActionplusLocalizations.load(locale);

  @override
  bool shouldReload(ActionplusLocalizationsDelegate old) => false;
}
