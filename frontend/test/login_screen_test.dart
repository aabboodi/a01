import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/application/services/auth_service.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/features/admin/admin_dashboard.dart';

// A mock AuthService for testing purposes
class MockAuthService implements AuthService {
  final bool shouldSucceed;

  const MockAuthService({this.shouldSucceed = true});

  @override
  Future<Map<String, dynamic>> login(String loginCode) async {
    if (shouldSucceed) {
      return Future.value({
        'role': 'admin',
        'user_id': 'admin-id',
        'login_code': loginCode,
      });
    } else {
      throw Exception('Login failed.');
    }
  }
}

void main() {
  testWidgets('LoginScreen shows required widgets', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(MaterialApp(home: LoginScreen(authService: const MockAuthService())));

    // Act
    final textField = find.byType(TextField);
    final button = find.byType(ElevatedButton);

    // Assert
    expect(textField, findsOneWidget);
    expect(button, findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });

  testWidgets('shows error when login code is empty', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(MaterialApp(home: LoginScreen(authService: const MockAuthService())));

    // Act
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // Let the snackbar animation finish

    // Assert
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('الرجاء إدخال كود الدخول'), findsOneWidget);
  });

  testWidgets('navigates to dashboard on successful login', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authService: const MockAuthService(shouldSucceed: true)),
        // Define routes for navigation testing
        routes: {
          '/admin_dashboard': (_) => const AdminDashboard(),
        },
      ),
    );

    // Act
    await tester.enterText(find.byType(TextField), 'admincode');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle(); // Wait for navigation to complete

    // Assert
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(AdminDashboard), findsOneWidget);
  });

  testWidgets('shows error on failed login', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(authService: const MockAuthService(shouldSucceed: false))),
    );

    // Act
    await tester.enterText(find.byType(TextField), 'wrongcode');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Assert
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Exception: Login failed.'), findsOneWidget);
  });
}
