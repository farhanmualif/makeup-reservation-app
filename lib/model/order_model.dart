class OrderModel {
  final String address;
  final String date;
  final String time;
  final String status;
  final String paymentStatus;
  final double totalPrice;
  final String userUid;
  final String packetId;

  OrderModel({
    required this.address,
    required this.date,
    required this.time,
    required this.status,
    required this.paymentStatus,
    required this.totalPrice,
    required this.userUid,
    required this.packetId,
  });

  factory OrderModel.fromMap(Map<String, dynamic> data) {
    return OrderModel(
      address: data['Address'] ?? '',
      date: data['Date'] ?? '',
      time: data['Time'] ?? '',
      status: data['Status'] ?? '',
      paymentStatus: data['PaymentStatus'] ?? '',
      totalPrice: data['TotalPrice']?.toDouble() ?? 0.0,
      userUid: data['UserUid'] ?? '',
      packetId: data['PacketId'] ?? '',
    );
  }
}
