import 'package:flutter/material.dart';
import 'data.dart';
import 'menu.dart';

class OrderManagementScreen extends StatefulWidget {
  @override
  _OrderManagementScreenState createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
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

          final orders = snapshot.data!;

 return orders.isEmpty
 ? Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.inbox,
 size: 80,
 color: Colors.grey,
                  ),
 SizedBox(height: 16),
 Text(
 'No orders yet',
 style: TextStyle(
 fontSize: 18,
 color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
 : ListView.builder(
 itemCount: orders.length,
 itemBuilder: (context, index) {
 final order = orders[orders.length - 1 - index]; // Show latest first
 return Card(
 margin: EdgeInsets.all(8),
 child: ExpansionTile(
 title: Text('Order #${order.id}'),
 subtitle: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text('Student: ${order.studentName}'),
 Text('Pickup Time: ${order.pickupTime}'),
 Text('Total: ₹${order.totalAmount.toStringAsFixed(0)}'),
 Text('Status: ${order.status.toUpperCase()}'),
                    ],
                  ),
 children: [
 ...order.items.map((item) => ListTile(
 title: Text(item.menuItem.name),
 subtitle: Text('Quantity: ${item.quantity}'),
 trailing: Text('₹${(item.menuItem.price * item.quantity).toStringAsFixed(0)}'),
                    )),
 Padding(
 padding: EdgeInsets.all(8),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                          ElevatedButton(
                            onPressed: order.status == 'pending' ? () {
                              updateOrderStatus(order.id, 'preparing');
                            } : null,
                            child: Text('Start Preparing'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: order.status == 'preparing' ? () {
                              updateOrderStatus(order.id, 'ready');
                            } : null,
                            child: Text('Mark Ready'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: order.status == 'ready' ? () {
                              updateOrderStatus(order.id, 'completed');
                            } : null,
                            child: Text('Complete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },

          );
  }

 Future<void> updateOrderStatus(String orderId, String status) async {
 await DataService.updateOrderStatus(orderId, status);
  }
}
