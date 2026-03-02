import 'package:intl/intl.dart';

class Formatters {
  // Equivalente a tu formatAmount()
  static String formatAmount(double amount, {String symbol = '\$'}) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2, // Ajusta a 0 si no quieres decimales
      locale: 'en_US',
    );
    return currencyFormatter.format(amount);
  }

  // Equivalente a tu formatDate()
  static String formatDate(String dateString) {
    try {
      final DateTime parsedDate = DateTime.parse(dateString);
      // Formato típico: 26/02/2026
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Fecha inválida';
    }
  }
}
