import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BrightnessMode { automatic, manual }

class DisplaySettings extends ChangeNotifier {
  static const _kMode = 'barcode_brightness_mode';
  static const _kManual = 'barcode_manual_brightness';
  static const double minBrightness = 0.3;

  BrightnessMode _mode = BrightnessMode.automatic;
  BrightnessMode get mode => _mode;

  double _manualBrightness = 1.0;
  double get manualBrightness => _manualBrightness;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final modeIndex = p.getInt(_kMode) ?? 0;
    _mode = BrightnessMode.values[modeIndex.clamp(0, 1)];
    _manualBrightness = p.getDouble(_kManual) ?? 1.0;
    notifyListeners();
  }

  Future<void> setMode(BrightnessMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kMode, mode.index);
    notifyListeners();
  }

  Future<void> setManualBrightness(double value) async {
    final clamped = value.clamp(minBrightness, 1.0);
    if (_manualBrightness == clamped) return;
    _manualBrightness = clamped;
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kManual, clamped);
    notifyListeners();
  }
}
