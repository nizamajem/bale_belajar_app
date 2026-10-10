import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bale_belajar_app/features/baleverse/domain/baleverse_models.dart';
import 'package:bale_belajar_app/features/baleverse/presentation/screens/dashboard_screen.dart';

void main() {
  for (final textScale in [1.0, 1.3]) {
    testWidgets('world list fits a small screen at text scale $textScale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? selected;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
              size: const Size(360, 640),
              textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: DashboardScreen(
              selectedWorld: const BaleWorld(
                  key: BaleWorldKey.numeria,
                  name: 'Numeria',
                  subject: 'Matematika',
                  characterClass: '',
                  color: Colors.blue,
                  mastery: 0),
              realUserName: 'Siswa',
              gameProfile: null,
              masteryAverage: null,
              realWorlds: List.generate(
                  8,
                  (i) => {
                        'key': 'world-$i',
                        'name': 'Dunia latihan $i',
                        'subject': 'Bahasa Korea',
                      }),
              worldMasteryAverages: const {},
              selectedBackendWorldKey: 'world-0',
              onSelectWorld: (world) => selected = world,
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Dunia latihan 0'));
      expect(selected?['key'], 'world-0');
      await tester.scrollUntilVisible(find.text('Dunia latihan 7'), 150,
          scrollable: find.byType(Scrollable));
      expect(tester.takeException(), isNull);
    });
  }
}
