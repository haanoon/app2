import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu.dart' as app_models;

class DataService {
  static Stream<List<app_models.MenuItem>> getMenuItemsStream() {
    return FirebaseFirestore.instance
        .collection('menuItems')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_models.MenuItem.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  static Stream<List<app_models.Order>> getOrdersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_models.Order.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  static Future<void> addOrder(app_models.Order order) async {
    final orderWithDate = app_models.Order(
      id: order.id,
      studentId: order.studentId,
      studentName: order.studentName,
      items: order.items,
      totalAmount: order.totalAmount,
      orderTime: order.orderTime,
      pickupTime: order.pickupTime,
      date: order.date ?? DateTime.now(),
      status: order.status,
    );
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(order.id)
        .set(orderWithDate.toFirestore());
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': status});
  }

  static Future<void> updateMenuItem(app_models.MenuItem item) async {
    await FirebaseFirestore.instance
        .collection('menuItems')
        .doc(item.id)
        .update(item.toMap());
  }

  static Future<void> addMenuItem(app_models.MenuItem item) async {
    await FirebaseFirestore.instance
        .collection('menuItems')
        .doc(item.id)
        .set(item.toMap());
  }

  static Future<void> removeMenuItem(String id) async {
    await FirebaseFirestore.instance
        .collection('menuItems')
        .doc(id)
        .delete();
  }
}
