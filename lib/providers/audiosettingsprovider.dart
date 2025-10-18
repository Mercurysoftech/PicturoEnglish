import 'package:flutter/foundation.dart';

class AudioSettingsProvider extends ChangeNotifier {
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  void setMute(bool value) {
    _isMuted = value;
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
  }

  void reset() {
    _isMuted = false;
    _isSpeakerOn = false;
    notifyListeners();
  }
}
