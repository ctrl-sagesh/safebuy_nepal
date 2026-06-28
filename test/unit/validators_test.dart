// SafeBuy Nepal — Validators Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:safebuy_nepal/core/utils/validators.dart';

void main() {
  group('Validators.nepaliPhone', () {
    test('accepts valid 10-digit numbers starting with 97 or 98', () {
      expect(Validators.nepaliPhone('9841234567'), isNull);
      expect(Validators.nepaliPhone('9751234567'), isNull);
      expect(Validators.nepaliPhone('9861234567'), isNull);
    });

    test('rejects null and empty', () {
      expect(Validators.nepaliPhone(null), isNotNull);
      expect(Validators.nepaliPhone(''), isNotNull);
      expect(Validators.nepaliPhone('   '), isNotNull);
    });

    test('rejects wrong length', () {
      expect(Validators.nepaliPhone('98412345'), isNotNull); // 8 digits
      expect(Validators.nepaliPhone('984123456'), isNotNull); // 9 digits
      expect(Validators.nepaliPhone('98412345678'), isNotNull); // 11 digits
    });

    test('rejects wrong prefix', () {
      expect(Validators.nepaliPhone('1234567890'), isNotNull);
      expect(Validators.nepaliPhone('1041234567'), isNotNull);
      expect(Validators.nepaliPhone('9941234567'), isNotNull);
    });

    test('strips non-digits before length check', () {
      // 10 digits with separators → valid (separators stripped)
      expect(Validators.nepaliPhone('984-123-4567'), isNull);
      // 13 digits after stripping +977 prefix → still invalid (too many)
      expect(Validators.nepaliPhone('+977 9841234567'), isNotNull);
    });
  });

  group('Validators.sanitize', () {
    test('strips HTML tags', () {
      expect(Validators.sanitize('<b>bold</b>'), 'bold');
      expect(Validators.sanitize('<script>evil()</script>hi'), 'evil()hi');
      expect(Validators.sanitize('<p>p1</p><p>p2</p>'), 'p1p2');
    });

    test('returns trimmed string unchanged if no HTML', () {
      expect(Validators.sanitize('  hello world  '), 'hello world');
    });
  });

  group('Validators.stripAtPrefix', () {
    test('strips leading @ symbol', () {
      expect(Validators.stripAtPrefix('@handle'), 'handle');
    });

    test('leaves clean handles untouched', () {
      expect(Validators.stripAtPrefix('handle'), 'handle');
      expect(Validators.stripAtPrefix(''), '');
    });
  });

  group('Validators.reportDescription', () {
    test('rejects descriptions under 50 chars', () {
      expect(Validators.reportDescription('Too short'), isNotNull);
      expect(Validators.reportDescription(''), isNotNull);
      expect(Validators.reportDescription(null), isNotNull);
    });

    test('accepts descriptions 50+ chars', () {
      const long =
          'This is a long enough description that meets the minimum char limit.';
      expect(Validators.reportDescription(long), isNull);
    });
  });

  group('Validators.positiveAmount', () {
    test('rejects null, empty, zero, negative', () {
      expect(Validators.positiveAmount(null), isNotNull);
      expect(Validators.positiveAmount(''), isNotNull);
      expect(Validators.positiveAmount('0'), isNotNull);
      expect(Validators.positiveAmount('-100'), isNotNull);
    });

    test('accepts positive numbers', () {
      expect(Validators.positiveAmount('1'), isNull);
      expect(Validators.positiveAmount('1500'), isNull);
      expect(Validators.positiveAmount('99999.99'), isNull);
    });
  });

  group('Validators.businessName', () {
    test('rejects short names', () {
      expect(Validators.businessName('A'), isNotNull);
      expect(Validators.businessName(''), isNotNull);
    });

    test('accepts valid names', () {
      expect(Validators.businessName('My Store'), isNull);
      expect(Validators.businessName('Priya Fashions'), isNull);
    });
  });

  group('Validators.esewaId', () {
    test('is optional (accepts empty)', () {
      expect(Validators.esewaId(null), isNull);
      expect(Validators.esewaId(''), isNull);
    });

    test('requires 10 digits when supplied', () {
      expect(Validators.esewaId('9841234567'), isNull);
      expect(Validators.esewaId('123'), isNotNull);
    });
  });
}
