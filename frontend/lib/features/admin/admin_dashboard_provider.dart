import 'package:flutter/material.dart';

/// A ChangeNotifier to manage the state of the AdminDashboard.
///
/// It holds the currently selected screen widget and provides a method
/// to update it, notifying listeners of the change.
class AdminDashboardProvider with ChangeNotifier {
  Widget _selectedScreen = const Center(child: Text('الرجاء تحديد قسم من القائمة'));

  /// The currently selected screen to be displayed in the dashboard body.
  Widget get selectedScreen => _selectedScreen;

  /// Updates the selected screen and notifies listeners.
  void navigateTo(Widget screen) {
    _selectedScreen = screen;
    notifyListeners();
  }
}
