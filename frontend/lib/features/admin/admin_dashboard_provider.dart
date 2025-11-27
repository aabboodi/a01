import 'package:flutter/material.dart';
import 'package:frontend/features/admin/admin_home_screen.dart'; // Import the new home screen

/// A ChangeNotifier to manage the state of the AdminDashboard.
///
/// It holds the currently selected screen widget and provides a method
/// to update it, notifying listeners of the change.
class AdminDashboardProvider with ChangeNotifier {
  Widget _selectedScreen = AdminHomeScreen(); // Set the new home screen as the default

  /// The currently selected screen to be displayed in the dashboard body.
  Widget get selectedScreen => _selectedScreen;

  /// Updates the selected screen and notifies listeners.
  void navigateTo(Widget screen) {
    _selectedScreen = screen;
    notifyListeners();
  }
}
