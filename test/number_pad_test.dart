import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/ui/number_pad.dart';

void main() {
  String type(List<String> keys) =>
      keys.fold('', (text, key) => applyKey(text, key));

  test('digits build a number, no leading zeros', () {
    expect(type(['1', '2', '3']), '123');
    expect(type(['0', '7']), '7');
    expect(type(['0', '0']), '0');
  });

  test('sign toggles, also on an empty field', () {
    expect(type(['5', '±']), '-5');
    expect(type(['5', '±', '±']), '5');
    expect(type(['±', '8']), '-8');
    expect(type(['±', '±']), '');
    expect(type(['-', '0'].map((k) => k == '-' ? '±' : k).toList() + ['4']), '-4');
  });

  test('backspace removes the last character', () {
    expect(type(['1', '2', '⌫']), '1');
    expect(type(['⌫']), '');
    expect(type(['±', '1', '⌫', '⌫']), '');
  });

  test('digit count is limited', () {
    expect(type(['1', '2', '3', '4', '5', '6', '7']), '123456');
  });
}
