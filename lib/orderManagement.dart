import 'package:flutter/material.dart';
import 'data.dart';
import 'menu.dart';

class OrderManagementScreen extends StatefulWidget {
  @override
  _OrderManagementScreenState createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  String _selectedDate = 'All';

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
        // Extract unique dates from orders
        final dateSet = <String>{'All'};
        for (var order in orders) {
          dateSet.add(order.date.toIso8601String().substring(0, 10));
        }
        final dateList = dateSet.toList()..sort((a, b) => b.compareTo(a));

        // Filter orders by selected date
        final filteredOrders = _selectedDate == 'All'
            ? orders
            : orders.where((order) => order.date.toIso8601String().substring(0, 10) == _selectedDate).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text('Date: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedDate,
                    items: dateList.map((date) => DropdownMenuItem(
                      value: date,
                      child: Text(date == 'All' ? 'All' : date),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDate = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredOrders.isEmpty
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
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[filteredOrders.length - 1 - index]; // Show latest first
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
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await DataService.updateOrderStatus(orderId, status);
  }
}
