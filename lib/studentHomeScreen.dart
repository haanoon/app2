import 'package:flutter/material.dart';
import 'data.dart';
import 'menu.dart';
import 'cart.dart';

class StudentHomeScreen extends StatefulWidget {
  final String mobileNumber;
  const StudentHomeScreen({Key? key, required this.mobileNumber}) : super(key: key);
  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  List<OrderItem> cart = [];
  String selectedCategory = 'All';
  bool showMyOrders = false;

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      'Main Course',
      'South Indian',
      'Snacks',
      'Beverages'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Menu'),
        actions: [
          IconButton(
            icon: Stack(children: [
              Icon(Icons.shopping_cart),
              if (cart.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen(
                      cart: cart,
                      onCartUpdated: (updatedCart) {
                        setState(() {
                          cart = updatedCart;
                        });
                      },
                      mobileNumber: widget.mobileNumber,
                    )),
              );
            },
          ),
        ],
      ),
      body: showMyOrders
          ? Column(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My Orders',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setState(() => showMyOrders = false),
                      child: Text('Back to Menu'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Order>>(
                  stream: DataService.getOrdersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error loading orders: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final allOrders = snapshot.data!;
                    final myOrders = allOrders
                        .where((order) => order.studentId == widget.mobileNumber)
                        .toList();

                    return myOrders.isEmpty
                        ? Center(child: Text('No orders yet.'))
                        : ListView.builder(
                            itemCount: myOrders.length,
                            itemBuilder: (context, index) {
                              final order = myOrders[
                                  myOrders.length - 1 - index]; // Latest first
                              return Card(
                                margin: EdgeInsets.all(8),
                                child: ListTile(
                                  title: Text('Order #${order.id}'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Status: ${order.status.toUpperCase()}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text('Pickup Time: ${order.pickupTime}'),
                                      ...order.items.map((item) => Text(
                                          '${item.menuItem.name} x${item.quantity}')),
                                      Text(
                                          'Total: ₹${order.totalAmount.toStringAsFixed(0)}'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                  },
                ),
              ),
            ])
          : Column(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Menu',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setState(() => showMyOrders = true),
                      child: Text('Track My Orders'),
                    ),
                  ],
                ),
              ),
              // Category Filter
              Container(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected:
                            isSelected, // corrected 'selected' to 'isSelected'
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        // added missing trailing comma
                      ),
                    );
                  },
                ),
              ),
              // Menu Items
              Expanded(child: StreamBuilder<List<MenuItem>>(
                stream: DataService.getMenuItemsStream(),
                builder: (context, menuSnapshot) {
                  if (menuSnapshot.hasError) {
                    return Center(
                        child: Text('Error loading menu: ${menuSnapshot.error}'));
                  }
                  if (!menuSnapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final menuItems = menuSnapshot.data!;
                  final filteredItems = selectedCategory == 'All'
                      ? menuItems
                      : menuItems
                          .where((item) => item.category == selectedCategory)
                          .toList();

                  return StreamBuilder<List<Order>>(
                    stream: DataService.getOrdersStream(),
                    builder: (context, orderSnapshot) {
                      if (orderSnapshot.hasError) {
                        return Center(
                            child:
                                Text('Error loading orders: ${orderSnapshot.error}'));
                      }
                      if (!orderSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final orders = orderSnapshot.data!;

                      return ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final totalOrdered = orders.fold<int>(0, (sum, order) {
                            return sum +
                                order.items
                                    .where((oi) => oi.menuItem.id == item.id)
                                    .fold(0, (s, oi) => s + oi.quantity);
                          });
                          final remaining = item.availableQuantity == -1
                              ? null
                              : (item.availableQuantity - totalOrdered);

                          return Card(
                            margin: EdgeInsets.all(8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade300,
                                    child: Icon(Icons.food_bank),
                                  );
                                },
                              ),
                              // added missing trailing comma
                              ),
                              title: Text(
                                item.name,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.description),
                                  Text(
                                    '₹${item.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (remaining != null)
                                    Text('Available: $remaining left today',
                                        style: TextStyle(color: Colors.blue)),
                                ],
                              ),
                              trailing: item.isAvailable &&
                                      (remaining == null || remaining > 0)
                                  ? ElevatedButton(
                                onPressed: () {
                                  if (remaining != null) {
                                    final cartCount = cart
                                        .where((c) =>
                                            c.menuItem.id == item.id)
                                        .fold(0, (s, c) => s + c.quantity);
                                    if (cartCount + 1 > remaining) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Only $remaining left for today!')),
                                      );
                                      return;
                                    }
                                  }
                                  addToCart(item);
                                },
                                child: Text('Add'),
                                style: ElevatedButton.styleFrom(minimumSize: Size(60, 30)),
                              )
                                  : Text(
                                'Unavailable',
                                style: TextStyle(color: Colors.red),
                              ),
                              // added missing trailing comma
                            ),
                          );
                        },
                      );
                    }, // added missing closing parenthesis
                  ); // added missing closing parenthesis
                },
                ),
              ),
            ]),
    );
  }

  void addToCart(MenuItem item) {
    setState(() {
      final existingIndex = cart.indexWhere((cartItem) => cartItem.menuItem.id == item.id);
      if (existingIndex != -1) {
        cart[existingIndex].quantity++;
      } else {
        cart.add(OrderItem(menuItem: item));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} added to cart!')),
    );
  }
}
