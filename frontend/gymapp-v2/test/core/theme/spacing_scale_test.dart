import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Spacing scale regression guard (lib geneli)', () {
    test('lib genelinde ölçek dışı SizedBox boşluğu yok', () {
      final offScale = RegExp(r'SizedBox\((height|width): (2|6|20|40)\)');
      final targetDirs = [
        Directory('lib'),
      ];

      final matchingSites = <String>[];

      for (final dir in targetDirs) {
        if (!dir.existsSync()) continue;
        final files = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        for (final file in files) {
          final content = file.readAsStringSync();
          final matches = offScale.allMatches(content);
          for (final match in matches) {
            matchingSites.add('${file.path}: ${match.group(0)}');
          }
        }
      }

      expect(
        matchingSites,
        isEmpty,
        reason: 'Ölçek dışı SizedBox değerleri bulundu: \n${matchingSites.join('\n')}',
      );
    });
  });
}
