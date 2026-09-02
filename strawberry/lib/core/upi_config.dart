/// School's UPI receiving details, used to build the UPI payment deep link.
///
/// IMPORTANT: Isse apne school/institute ki real UPI ID se replace karo
/// deploy karne se pehle. `vpa` wahi UPI ID hai jispar payment aayegi
/// (jaise apka bank/GPay/PhonePe UPI ID).
class UpiConfig {
  /// School's UPI Virtual Payment Address, e.g. "school@okhdfcbank"
  static const String vpa = 'nyasa14@cnrb';

  /// Payee name shown inside the UPI app during payment
  static const String payeeName = 'Nyasa Arora';
}
