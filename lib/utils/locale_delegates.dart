import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class KurdishMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const KurdishMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'ckb' || locale.languageCode == 'bhn';
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // Load Arabic localizations for Kurdish languages
    return GlobalMaterialLocalizations.delegate.load(const Locale('ar'));
  }

  @override
  bool shouldReload(LocalizationsDelegate<MaterialLocalizations> old) => false;
}

class AssyrianMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const AssyrianMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'arc';
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // Load English localizations for Assyrian language
    return GlobalMaterialLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(LocalizationsDelegate<MaterialLocalizations> old) => false;
}

class KurdishCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const KurdishCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'ckb' || locale.languageCode == 'bhn';
  }

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    // Load Arabic localizations for Kurdish languages
    return GlobalCupertinoLocalizations.delegate.load(const Locale('ar'));
  }

  @override
  bool shouldReload(LocalizationsDelegate<CupertinoLocalizations> old) => false;
}

class AssyrianCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const AssyrianCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'arc';
  }

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    // Load English localizations for Assyrian language
    return GlobalCupertinoLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(LocalizationsDelegate<CupertinoLocalizations> old) => false;
}