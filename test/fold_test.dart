import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/text/fold.dart';

/// Checks fold.dart against fold_test_vectors.json (shared with
/// tool/test_fold.py) -- see lib/core/text/fold.dart's doc comment.
void main() {
  final vectorsFile = File('tool/fold_test_vectors.json');
  final vectors = (jsonDecode(vectorsFile.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  for (final v in vectors) {
    final input = v['input'] as String;
    final expected = v['folded'] as String;
    test('foldForSearch(${jsonEncode(input)}) == ${jsonEncode(expected)}', () {
      expect(foldForSearch(input), expected);
    });
  }
}
