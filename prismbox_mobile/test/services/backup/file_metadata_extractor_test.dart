// test/services/backup/file_metadata_extractor_test.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:prismbox/services/backup/file_metadata_extractor.dart';

void main() {
  group('FileMetadataExtractor', () {
    late FileMetadataExtractor extractor;

    setUp(() {
      extractor = FileMetadataExtractor();
    });

    group('extractFileSize', () {
      test('应该返回文件大小当文件存在时', () async {
        // Arrange
        final tempFile = File('/tmp/test_size.jpg');
        const content = 'test content for size calculation';
        await tempFile.create(recursive: true);
        await tempFile.writeAsString(content);

        try {
          // Act
          final size = await extractor.extractFileSize('/tmp/test_size.jpg');

          // Assert
          expect(size, greaterThan(0));
          expect(size, equals(content.length));
        } finally {
          // Cleanup
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      });

      test('应该返回0当文件不存在时', () async {
        // Act
        final size = await extractor.extractFileSize('/nonexistent/file.jpg');

        // Assert
        expect(size, equals(0));
      });

      test('应该返回0当路径无效时', () async {
        // Act
        final size = await extractor.extractFileSize('');

        // Assert
        expect(size, equals(0));
      });
    });
  });
}

