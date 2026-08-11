import 'package:flutter_test/flutter_test.dart';
import 'package:safebuy_nepal/core/utils/phone_extractor.dart';

void main() {
  group('PhoneExtractor.extract', () {
    test('pulls a bare Nepali mobile from a sentence', () {
      expect(PhoneExtractor.extract('Pay me at 9841234567 please'),
          '9841234567');
    });

    test('strips +977 country code and spacing', () {
      expect(PhoneExtractor.extract('Contact +977 9841234567'),
          '9841234567');
      expect(PhoneExtractor.extract('call +977-9812345678 now'),
          '9812345678');
    });

    test('extracts a @handle when no phone present', () {
      expect(PhoneExtractor.extract('follow @priya_fashions on tiktok'),
          '@priya_fashions');
    });

    test('prefers a phone over a handle', () {
      expect(
          PhoneExtractor.extract('@shop 9861234567'), '9861234567');
    });

    test('returns null when nothing matches', () {
      expect(PhoneExtractor.extract('no identifier here'), isNull);
    });
  });

  group('PhoneExtractor.isValid', () {
    test('accepts a 10-digit 98/97 number', () {
      expect(PhoneExtractor.isValid('9841234567'), isTrue);
      expect(PhoneExtractor.isValid('9712345678'), isTrue);
    });

    test('rejects wrong length or prefix', () {
      expect(PhoneExtractor.isValid('12345'), isFalse);
      expect(PhoneExtractor.isValid('1234567890'), isFalse);
    });

    test('accepts a handle longer than 2 chars', () {
      expect(PhoneExtractor.isValid('@ab'), isTrue);
      expect(PhoneExtractor.isValid('@a'), isFalse);
    });

    test('rejects null', () {
      expect(PhoneExtractor.isValid(null), isFalse);
    });
  });
}
