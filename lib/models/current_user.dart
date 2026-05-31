import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CurrentUser {
  static final CurrentUser _instance = CurrentUser._();
  static CurrentUser get instance => _instance;

  String? _authToken;
  String? _userId;
  String? _email;
  String? _displayName;
  String? _avatarUrl;

  bool get loggedIn => _authToken != null;
  String? get authToken => _authToken;
  String? get userId => _userId;
  String? get email => _email;
  String? get displayName => _displayName;
  String? get avatarUrl => _avatarUrl;
  String get authorization => 'Bearer ${_authToken ?? ''}';

  CurrentUser._();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('current_user');
    if (json != null) {
      final data = Map<String, dynamic>.from(jsonDecode(json) as Map);
      _authToken = data['authToken'] as String?;
      _userId = data['userId'] as String?;
      _email = data['email'] as String?;
      _displayName = data['displayName'] as String?;
      _avatarUrl = data['avatarUrl'] as String?;
    }
  }

  Future<void> login({
    required String authToken,
    required String userId,
    required String email,
    required String displayName,
    String? avatarUrl,
  }) async {
    _authToken = authToken;
    _userId = userId;
    _email = email;
    _displayName = displayName;
    _avatarUrl = avatarUrl;

    await _persist();
  }

  Future<void> logout() async {
    _authToken = null;
    _userId = null;
    _email = null;
    _displayName = null;
    _avatarUrl = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode({
      'authToken': _authToken,
      'userId': _userId,
      'email': _email,
      'displayName': _displayName,
      'avatarUrl': _avatarUrl,
    }));
  }
}
