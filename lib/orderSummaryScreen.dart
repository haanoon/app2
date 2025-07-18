import 'package:flutter/material.dart';
import 'data.dart';
import 'menu.dart';

class OrderSummaryScreen extends StatefulWidget {
  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  String _selectedPickupTime = 'All';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: DataService.getOrdersStream(),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.hasError) {
          return Center(child: Text('Error loading orders: \\${orderSnapshot.error}'));
        }
        if (!orderSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final orders = orderSnapshot.data!;
        final pickupTimes = <String>{'All'};
        for (var order in orders) {
          pickupTimes.add(order.pickupTime);
        }

        // Filter orders by selected pickup time
        final filteredOrders = _selectedPickupTime == 'All'
            ? orders
            : orders.where((order) => order.pickupTime == _selectedPickupTime).toList();

        // Map of menuItemId to total quantity
        final Map<String, int> itemQuantities = {};
        for (var order in filteredOrders) {
          for (var orderItem in order.items) {
            itemQuantities[orderItem.menuItem.id] =
                (itemQuantities[orderItem.menuItem.id] ?? 0) + orderItem.quantity;
          }
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text('Pickup Time: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedPickupTime,
                    items: pickupTimes.map((time) => DropdownMenuItem(
                      value: time,
                      child: Text(time),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPickupTime = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<MenuItem>>(
                stream: DataService.getMenuItemsStream(),
                builder: (context, menuSnapshot) {
                  if (menuSnapshot.hasError) {
                    return Center(child: Text('Error loading menu: \\${menuSnapshot.error}'));
                  }
                  if (!menuSnapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final menuItems = menuSnapshot.data!;

                  return menuItems.isEmpty
                      ? Center(child: Text('No menu items.'))
                      : ListView.builder(
                          itemCount: menuItems.length,
                          itemBuilder: (context, index) {
                            final item = menuItems[index];
                            final qty = itemQuantities[item.id] ?? 0;
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Text(item.name),
                              ),
                              title: Text(item.name),
                              trailing: Text(
                                'Total Ordered: $qty',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: qty > 0 ? Colors.orange : Colors.grey,
                                ),
                              ),
                            );
                          },
                        );
                },
              ),
            ),
          ],
        );
      },
    );
  }
} 