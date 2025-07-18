import 'package:flutter/material.dart';
import 'menu.dart';
import 'data.dart';

class CartScreen extends StatefulWidget {
  final List<OrderItem> cart;
  final Function(List<OrderItem>) onCartUpdated;
  final String mobileNumber;

  CartScreen({required this.cart, required this.onCartUpdated, required this.mobileNumber});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedPickupTime;
  final List<String> _pickupTimes = [
    '10:30 AM (Break)',
    '1:00 PM (Lunch)',
    'Other...'
  ];
  String? _customPickupTime;

  @override
  Widget build(BuildContext context) {
    double total = widget.cart.fold(0, (sum, item) => sum + (item.menuItem.price * item.quantity));

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Cart'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.cart.length,
              itemBuilder: (context, index) {
                final cartItem = widget.cart[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(cartItem.menuItem.name),
                    subtitle: Text('₹${cartItem.menuItem.price.toStringAsFixed(0)} each'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (cartItem.quantity > 1) {
                                cartItem.quantity--;
                              } else {
                                widget.cart.removeAt(index);
                              }
                            });
                            widget.onCartUpdated(widget.cart);
                          },
                        ),
                        Text('${cartItem.quantity}'),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              cartItem.quantity++;
                            });
                            widget.onCartUpdated(widget.cart);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ₹${total.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: widget.cart.isEmpty ? null : () async {
                        if (_nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please enter your name')),
                          );
                          return;
                        }
                        await _showPickupTimeDialog(context, total);
                      },
                      child: Text('Place Order'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPickupTimeDialog(BuildContext context, double total) async {
    _selectedPickupTime = _pickupTimes[0];
    _customPickupTime = null;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Pickup Time'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: _selectedPickupTime,
                    items: _pickupTimes.map((time) {
                      return DropdownMenuItem<String>(
                        value: time,
                        child: Text(time),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPickupTime = value;
                        if (value != 'Other...') _customPickupTime = null;
                      });
                    },
                  ),
                  if (_selectedPickupTime == 'Other...')
                    TextField(
                      decoration: InputDecoration(labelText: 'Enter custom time'),
                      onChanged: (val) {
                        setState(() {
                          _customPickupTime = val;
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    String pickupTime = _selectedPickupTime == 'Other...'
                        ? (_customPickupTime?.trim().isNotEmpty == true ? _customPickupTime! : '')
                        : _selectedPickupTime!;
                    if (pickupTime.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select or enter a pickup time')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    placeOrder(total, pickupTime);
                  },
                  child: Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> placeOrder(double total, String pickupTime) async {
    // Check for available quantity for each item
    for (final cartItem in widget.cart) {
      final orders = await DataService.getOrdersStream().first; // Fetch latest orders to check availability
      final item = cartItem.menuItem;
      if (item.availableQuantity != -1) {
        final totalOrdered = orders.fold<int>(0, (sum, order) {
          return sum + order.items.where((oi) => oi.menuItem.id == item.id).fold(0, (s, oi) => s + oi.quantity);
        });
        final remaining = item.availableQuantity - totalOrdered;
        if (cartItem.quantity > remaining) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Only $remaining of ${item.name} left for today!')),
          );
          return;
        }
      }
    }
    final order = Order( // Generate a local Order object first
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: widget.mobileNumber,
      studentName: _nameController.text.trim(),
      items: List.from(widget.cart),
      totalAmount: total,
      orderTime: DateTime.now(),
      pickupTime: pickupTime,
      date: DateTime.now(),
    );

    await DataService.addOrder(order); // Use await to ensure the order is added before proceeding
    widget.cart.clear();
    widget.onCartUpdated(widget.cart);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order placed for $pickupTime! Order ID: ${order.id}')),
    );
  }
}
