import 'package:flutter/material.dart';
import 'package:zonix/features/DomainProfiles/Profiles/models/profile_model.dart';

class UserProvider with ChangeNotifier {
  Profile? _profile;

  Profile? get profile => _profile;

  void setProfile(Profile profile) {
    _profile = profile;
    notifyListeners();
  }

  void clearProfile() {
    _profile = null;
    notifyListeners();
  }
}
