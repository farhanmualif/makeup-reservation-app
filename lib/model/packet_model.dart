class Packet {
  final String name;
  final String description;
  final String image;
  final String price;

  Packet({
    required this.name,
    required this.description,
    required this.image,
    required this.price,
  });

  factory Packet.fromMap(Map<String, dynamic> data) {
    return Packet(
      name: data['Name'] ?? '',
      description: data['Description'] ?? '',
      image: data['Image'] ?? '',
      price: data['Price'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Name': name,
      'Description': description,
      'Image': image,
      'Price': price,
    };
  }
}