/// Formato de precios en guaraníes (PYG).
abstract final class GuaraniFormatter {
  static const _units = [
    '',
    'uno',
    'dos',
    'tres',
    'cuatro',
    'cinco',
    'seis',
    'siete',
    'ocho',
    'nueve',
  ];

  static const _teens = [
    'diez',
    'once',
    'doce',
    'trece',
    'catorce',
    'quince',
    'dieciséis',
    'diecisiete',
    'dieciocho',
    'diecinueve',
  ];

  static const _tens = [
    '',
    '',
    'veinte',
    'treinta',
    'cuarenta',
    'cincuenta',
    'sesenta',
    'setenta',
    'ochenta',
    'noventa',
  ];

  static const _hundreds = [
    '',
    'ciento',
    'doscientos',
    'trescientos',
    'cuatrocientos',
    'quinientos',
    'seiscientos',
    'setecientos',
    'ochocientos',
    'novecientos',
  ];

  /// Etiqueta corta para UI: `₲ 25.000` o `Gratis`.
  static String format(int amount) {
    if (amount <= 0) return 'Gratis';
    return '₲ ${formatNumber(amount)}';
  }

  /// Etiqueta con palabras: `Veinticinco mil guaraníes`.
  static String formatInWords(int amount) {
    if (amount <= 0) return 'Gratis';
    final words = _toWords(amount);
    if (words.isEmpty) return 'Gratis';
    return '${_capitalize(words)} guaraníes';
  }

  /// Número con separador de miles paraguayo (punto), sin ceros a la izquierda.
  static String formatNumber(int value) {
    if (value <= 0) return '0';

    final digits = value.toString();
    final buffer = StringBuffer();
    var count = 0;

    for (var i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write('.');
        count = 0;
      }
    }

    return buffer.toString().split('').reversed.join();
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String _toWords(int number) {
    if (number == 0) return '';
    if (number < 0) return 'menos ${_toWords(-number)}';

    if (number < 10) return _units[number];
    if (number < 20) return _teens[number - 10];
    if (number < 100) {
      final ten = number ~/ 10;
      final unit = number % 10;
      if (unit == 0) return _tens[ten];
      if (ten == 2) return 'veinti${_units[unit]}';
      return '${_tens[ten]} y ${_units[unit]}';
    }
    if (number < 1000) {
      final hundred = number ~/ 100;
      final rest = number % 100;
      if (rest == 0) {
        return hundred == 1 ? 'cien' : _hundreds[hundred];
      }
      return '${_hundreds[hundred]} ${_toWords(rest)}';
    }
    if (number < 1000000) {
      final thousand = number ~/ 1000;
      final rest = number % 1000;
      final thousandWord =
          thousand == 1 ? 'mil' : '${_toWords(thousand)} mil';
      if (rest == 0) return thousandWord;
      return '$thousandWord ${_toWords(rest)}';
    }

    final million = number ~/ 1000000;
    final rest = number % 1000000;
    final millionWord =
        million == 1 ? 'un millón' : '${_toWords(million)} millones';
    if (rest == 0) return millionWord;
    return '$millionWord ${_toWords(rest)}';
  }
}
