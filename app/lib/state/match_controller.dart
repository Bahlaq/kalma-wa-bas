import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/players.dart';
import '../engine/engine.dart' as E;
import '../engine/models.dart';

enum AppView { home, setup, match }

class MatchController extends ChangeNotifier with WidgetsBindingObserver {
  MatchController();

  static const _saveKey = 'kalma-match-v1';
  static const _soundKey = 'kalma-sound';

  AppView view = AppView.home;
  MatchConfig setupConfig = MatchConfig.defaults();
  MatchState? match;
  bool soundOn = true;
  String? errorMessage;
  Timer? _ticker;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    final prefs = await SharedPreferences.getInstance();
    soundOn = prefs.getString(_soundKey) != 'off';
    final raw = prefs.getString(_saveKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (E.validSavedState(decoded)) {
          match = MatchState.fromJson(Map<String, dynamic>.from(decoded as Map));
          if (match!.phase == 'playing') {
            match = E.pause(match!);
          }
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (match?.phase == 'playing' && match?.current?.paused == false) {
        match = E.pause(match!);
        _persist();
        notifyListeners();
      }
    }
  }

  bool get hasActiveMatch => match != null && match!.phase != 'finished';

  int get poolPreviewCount =>
      E.makePool(builtinPlayers, setupConfig).length;

  void goHome() {
    if (match?.phase == 'playing') {
      match = E.pause(match!);
      _persist();
    }
    view = AppView.home;
    notifyListeners();
  }

  void goSetup({bool fromExisting = false}) {
    if (match?.phase == 'playing') {
      match = E.pause(match!);
      _persist();
    }
    if (fromExisting && match != null) {
      setupConfig = match!.config.copy();
    }
    view = AppView.setup;
    notifyListeners();
  }

  void resumeMatch() {
    if (match == null) return;
    view = AppView.match;
    _ensureTicker();
    notifyListeners();
  }

  void updateSetup(MatchConfig config) {
    setupConfig = config;
    notifyListeners();
  }

  void startNewMatch() {
    errorMessage = null;
    try {
      match = E.createMatch(setupConfig, builtinPlayers);
      view = AppView.match;
      _persist();
      _ensureTicker();
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Bad state: ', '');
      notifyListeners();
    }
  }

  void clearFinishedAndHome() {
    match = null;
    _clearSave();
    view = AppView.home;
    notifyListeners();
  }

  void toggleSound() {
    soundOn = !soundOn;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_soundKey, soundOn ? 'on' : 'off');
    });
    notifyListeners();
  }

  void markSeen() => _apply(E.markSeen);
  void acknowledge() => _apply(E.acknowledge);
  void startRound() => _apply((s) => E.startRound(s));

  void togglePause() {
    if (match?.phase != 'playing') return;
    final paused = match!.current!.paused;
    _apply(paused ? E.resume : E.pause);
  }

  String? addHint(String word) {
    if (match == null) return null;
    try {
      match = E.addHint(match!, word);
      _persist();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Bad state: ', '');
    }
  }

  void award(int team) {
    if (match?.phase != 'playing' || match?.current?.paused == true) return;
    _apply((s) => E.resolveRound(s, team, 'correct'));
  }

  void skipRound() {
    if (match?.phase != 'playing') return;
    if (match!.current?.paused == false) {
      match = E.pause(match!);
    }
    _apply((s) => E.resolveRound(s, null, 'skip'));
  }

  void timeoutRound() {
    if (match?.phase != 'playing') return;
    _apply((s) => E.resolveRound(s, null, 'timeout'));
  }

  void undoResult() => _apply(E.undoResult);

  void continueMatch() {
    _apply(E.continueMatch);
  }

  void endMatch() {
    if (match?.phase == 'playing') {
      match = E.pause(match!);
    }
    _apply(E.finishMatch);
  }

  void _apply(MatchState Function(MatchState) fn) {
    if (match == null) return;
    match = fn(match!);
    if (match!.phase == 'playing' &&
        match!.config.seconds > 0 &&
        E.remaining(match!) == 0) {
      match = E.resolveRound(match!, null, 'timeout');
    }
    _persist();
    _ensureTicker();
    notifyListeners();
  }

  void _ensureTicker() {
    _ticker?.cancel();
    if (match?.phase == 'playing' &&
        match?.current?.paused == false &&
        match?.config.seconds != 0) {
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (match?.phase != 'playing') {
          _ticker?.cancel();
          return;
        }
        final left = E.remaining(match!);
        if (left == 0) {
          match = E.resolveRound(match!, null, 'timeout');
          _persist();
          _ticker?.cancel();
        }
        notifyListeners();
      });
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (match == null || match!.phase == 'finished') {
      await prefs.remove(_saveKey);
      return;
    }
    await prefs.setString(_saveKey, jsonEncode(match!.toJson()));
  }

  Future<void> _clearSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }
}
