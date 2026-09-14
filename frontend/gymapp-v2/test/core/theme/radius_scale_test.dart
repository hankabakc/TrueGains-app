import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Radius scale regression guard (lib geneli)', () {
    test('lib genelinde ham BorderRadius.circular(12|16|20|24) yok', () {
      final offScale = RegExp(r'BorderRadius\.circular\((12|16|20|24)\)');
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
        reason: 'Ham BorderRadius.circular değerleri bulundu: \n${matchingSites.join('\n')}',
      );
    });
  });
}
