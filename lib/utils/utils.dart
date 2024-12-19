import 'package:intl/intl.dart';

String formatPrice(String price) {
  final cleanComaPrice = price.replaceAll(',', '');
  final cleanPrice = cleanComaPrice.replaceAll('.', '');

  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  return formatter.format(int.parse(cleanPrice));
}

String generateOrderId() {
  return 'TTMA-${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}${DateTime.now().millisecond}';
}
