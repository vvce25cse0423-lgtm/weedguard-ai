import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Field form validation', () {
    String? validateName(String? v) {
      if (v == null || v.trim().isEmpty) return 'Field name is required';
      return null;
    }

    String? validateArea(String? v) {
      if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Enter a valid number';
      return null;
    }

    test('empty name returns error', () => expect(validateName(''), isNotNull));
    test('blank name returns error', () => expect(validateName('   '), isNotNull));
    test('valid name returns null', () => expect(validateName('North Field'), isNull));
    test('valid area returns null', () => expect(validateArea('2.5'), isNull));
    test('invalid area returns error', () => expect(validateArea('abc'), isNotNull));
    test('empty area is allowed', () => expect(validateArea(''), isNull));
  });
}
