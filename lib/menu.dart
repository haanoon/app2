class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  bool isAvailable;
  int availableQuantity; // -1 means unlimited

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.isAvailable = true,
    this.availableQuantity = -1,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'category': category,
    'imageUrl': imageUrl,
    'isAvailable': isAvailable,
    'availableQuantity': availableQuantity,
  };

  static MenuItem fromMap(Map<String, dynamic> map) => MenuItem(
    id: map['id'],
    name: map['name'],
    description: map['description'],
    price: map['price'],
    category: map['category'],
    imageUrl: map['imageUrl'],
    isAvailable: map['isAvailable'] ?? true,
    availableQuantity: map['availableQuantity'] ?? -1,
  );
}

class OrderItem {
  final MenuItem menuItem;
  int quantity;

  OrderItem({required this.menuItem, this.quantity = 1});

  factory OrderItem.fromFirestore(Map<String, dynamic> map) {
    return OrderItem(
      menuItem: MenuItem.fromMap(map['menuItem'] as Map<String, dynamic>),
      quantity: map['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'menuItem': menuItem.toMap(),
        'quantity': quantity,
      };
}

class Order {
  final String id;
  final String studentId;
  final String studentName;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime orderTime;
  final String pickupTime;
  final DateTime date;
  String status; // pending, preparing, ready, completed

  Order({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.items,
    required this.totalAmount,
    required this.orderTime,
    required this.pickupTime,
    required this.date,
    this.status = 'pending',
  });

  factory Order.fromFirestore(Map<String, dynamic> map, String docId) {
    return Order(
      id: docId,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromFirestore(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      orderTime: (map['orderTime'] != null)
          ? DateTime.parse(map['orderTime'])
          : DateTime.now(),
      pickupTime: map['pickupTime'] ?? '',
      date: (map['date'] != null)
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'studentId': studentId,
        'studentName': studentName,
        'items': items.map((item) => item.toFirestore()).toList(),
        'totalAmount': totalAmount,
        'orderTime': orderTime.toIso8601String(),
        'pickupTime': pickupTime,
        'date': date.toIso8601String(),
        'status': status,
      };
}
