import 'package:flutter/material.dart';
import 'data.dart';
import 'menu.dart';

class PendingOrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: DataService.getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading orders: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final pendingOrders = snapshot.data!.where((order) => order.status == 'pending').toList();
        pendingOrders.sort((a, b) => b.orderTime.compareTo(a.orderTime)); // Sort by latest first

        if (pendingOrders.isEmpty) {
          return Center(
            child: Text('No pending orders yet.'),
          );
        }

        return ListView.builder(
            itemCount: pendingOrders.length,
            itemBuilder: (context, index) {
              final order = pendingOrders[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Order #${order.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Student: ${order.studentName}'),
                      ...order.items.map((item) => Text('${item.menuItem.name} x${item.quantity}')),
                      Text('Total: ₹${order.totalAmount.toStringAsFixed(0)}'),
                      Text('Status: ${order.status.toUpperCase()}'),
                    ],
                  ),
                ),
              );
            },
          );
      },
    );
  }
} 