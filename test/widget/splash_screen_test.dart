import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samabus/screens/splash_screen.dart'; // Adjust import if necessary

// Helper function to create the widget tree for testing
Widget createSplashScreen() {
  return const MaterialApp(
    home: SplashScreen(),
  );
}

void main() {
  testWidgets('SplashScreen renders correctly with loading indicator', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createSplashScreen());

    // Assert
    // Check if the SplashScreen widget itself is rendered
    expect(find.byType(SplashScreen), findsOneWidget);

    // Check for the basic structure (usually a Scaffold)
    expect(find.byType(Scaffold), findsOneWidget);

    // Check for the loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Add checks for specific branding elements if they exist, e.g.:
    // expect(find.byType(Image), findsOneWidget);
    // expect(find.text('Samabus'), findsOneWidget);
  });
} 