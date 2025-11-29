import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/class_service.dart';
import 'package:frontend/core/services/local_db_service.dart';

enum ClassListState {
  loading,
  loaded,
  error,
}

class ClassProvider with ChangeNotifier {
  final ClassService _classService = ClassService();
  final LocalDbService _localDbService = LocalDbService();

  List<dynamic> _classes = [];
  List<dynamic> get classes => _classes;

  ClassListState _state = ClassListState.loading;
  ClassListState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ClassProvider() {
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    _state = ClassListState.loading;
    notifyListeners();

    try {
      // Step 1: Immediately load from cache
      final cachedClasses = await _localDbService.getCachedClasses();
      if (cachedClasses.isNotEmpty) {
        _classes = cachedClasses;
        _state = ClassListState.loaded;
        notifyListeners();
      }

      // Step 2: Fetch from network
      final networkClasses = await _classService.getAllClasses();

      // Step 3: Update cache and notify listeners
      await _localDbService.cacheClasses(networkClasses);
      _classes = networkClasses;
      _state = ClassListState.loaded;
      notifyListeners();

    } catch (e) {
      // If network fails but we have cached data, we stay in 'loaded' state.
      // Only transition to 'error' if we have no data at all.
      if (_classes.isEmpty) {
        _state = ClassListState.error;
        _errorMessage = "Failed to load classes: ${e.toString()}";
      }
      notifyListeners();
    }
  }
}
