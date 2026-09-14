import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Card color regression guard (lib/features)', () {
    test('kenarlıklı BoxDecoration içinde ham beyaz renk kullanılmaz', () {
      final targetDir = Directory('lib/features');
      if (!targetDir.existsSync()) return;

      final files = targetDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];

      for (final file in files) {
        final content = file.readAsStringSync();
        var index = 0;
        const trigger = 'decoration: BoxDecoration(';

        while ((index = content.indexOf(trigger, index)) != -1) {
          final startParen = index + trigger.indexOf('(');
          var depth = 0;
          var blockEnd = startParen;
          for (var i = startParen; i < content.length; i++) {
            if (content[i] == '(') {
              depth++;
            } else if (content[i] == ')') {
              depth--;
              if (depth == 0) {
                blockEnd = i;
                break;
              }
            }
          }

          final block = content.substring(index, blockEnd + 1);

          if (block.contains('border: Border.all') &&
              block.contains('Colors.white')) {
            violations.add('${file.path} (karakter $index)');
          }
          index += trigger.length;
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Kenarlıklı BoxDecoration içinde ham Colors.white kullanımı bulundu:\n${violations.join('\n')}',
      );
    });
  });
}
