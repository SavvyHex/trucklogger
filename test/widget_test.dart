// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trucklogger/main.dart';

void main() {
  test('normalizes OCR plate text', () {
    expect(normalizePlateText('gj-37-v-0562'), 'GJ 37 V 0562');
    expect(normalizePlateText('  GJ 11 T 2290\n'), 'GJ 11 T 2290');
    expect(isValidIndianPlate('GJ 37 V 0562'), isTrue);
    expect(isValidIndianPlate('22BH1234AB'), isTrue);
    expect(isValidIndianPlate('WELCOME TO INDIA'), isFalse);
  });

  testWidgets('shows the truck log list and upload summary', (tester) async {
    await tester.pumpWidget(const TruckLoggerApp());

    expect(find.text('Truck log'), findsOneWidget);
    expect(find.text('GJ 37 V 0562'), findsOneWidget);
    expect(find.text('2 videos still uploading'), findsOneWidget);
    expect(find.text('New truck'), findsOneWidget);
  });

  testWidgets('opens the new truck entry flow', (tester) async {
    await tester.pumpWidget(const TruckLoggerApp());
    await tester.pump();
    await tester.tap(find.text('New truck'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('New truck entry'), findsOneWidget);
    expect(find.text('Plate number'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Save entry'), findsOneWidget);
  });

  testWidgets('adds another material row', (tester) async {
    await tester.pumpWidget(const TruckLoggerApp());
    await tester.pump();
    await tester.tap(find.text('New truck'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    await tester.tap(find.text('Add material'));
    await tester.pump();

    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(3));
  });

  testWidgets('opens a truck detail from the log list', (tester) async {
    await tester.pumpWidget(const TruckLoggerApp());
    await tester.tap(find.text('GJ 37 V 0562'));
    await tester.pumpAndSettle();

    expect(find.text('Truck entry'), findsOneWidget);
    expect(find.text('Islami Sea Food'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('opens pending uploads from the upload notification', (tester) async {
    await tester.pumpWidget(const TruckLoggerApp());
    await tester.tap(find.text('2 videos still uploading'));
    await tester.pumpAndSettle();

    expect(find.text('Pending uploads'), findsOneWidget);
    expect(find.text('GJ 03 BX 4417'), findsOneWidget);
  });

  testWidgets('opens app information from the overflow menu', (tester) async {
    await tester.pumpWidget(const TruckLoggerApp());
    await tester.tap(find.byTooltip('App information'));
    await tester.pumpAndSettle();

    expect(find.text('App information'), findsOneWidget);
    expect(find.text('Truck logger'), findsOneWidget);
    expect(find.text('Version 0.0.1'), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
  });

  testWidgets('opens the date picker from Pick date', (tester) async {
    await tester.pumpWidget(const TruckLoggerApp());
    await tester.tap(find.text('Pick date'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
