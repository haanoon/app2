import 'package:flutter/material.dart';
import 'data.dart';
import 'menu.dart';

class MenuManagementScreen extends StatefulWidget {
  @override
  _MenuManagementScreenState createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  // Although setState is used within dialogs, the main build method relies on the StreamBuilder
  // to update the list of menu items.
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: StreamBuilder<List<MenuItem>>(
        stream: DataService.getMenuItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading menu: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final menuItems = snapshot.data!;

          if (menuItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No menu items added yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
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
                  ),
                  title: Text(item.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.description),
                      Text('₹${item.price.toStringAsFixed(0)}'),
                      Text('Category: ${item.category}'),
                      Text('Available: ${item.availableQuantity == -1 ? "Unlimited" : item.availableQuantity}'),
                    ],
                  ),
                  trailing: Switch(
                    value: item.isAvailable,
                    onChanged: (value) {
                      // This state change will likely trigger a re-render of this specific ListTile or the whole list
                      // if the available quantity changes in a way that affects filtering/sorting (though not in this current implementation).
                      // The actual database update happens within the showEditItemDialog's save action.
                      setState(() {
                        item.isAvailable = value;
                        // You might want to immediately update the database here as well,
                        // but for simplicity and consistency with the save button, we'll do it in the dialog.
                        // DataService.updateMenuItem(item.copyWith(isAvailable: value)); // Example of immediate update
                      });
                      // If you update immediately here, consider if you still need the save button for other edits.
                    },
                  ),
                  onTap: () {
                    showEditItemDialog(item);
                  },
                  onLongPress: () {
                    showDeleteConfirmationDialog(item);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddItemDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void showAddItemDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();
    final availableQuantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: categoryController,
              decoration: InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: availableQuantityController,
              decoration: InputDecoration(labelText: 'Available Quantity (leave blank for unlimited)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async { // Make onPressed async
              if (nameController.text.trim().isNotEmpty &&
                  priceController.text.isNotEmpty) {
                final newItem = MenuItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  price: double.tryParse(priceController.text) ?? 0.0,
                  category: categoryController.text.isEmpty ? 'Other' : categoryController.text,
                  imageUrl: 'https://via.placeholder.com/150x100/95A5A6/FFFFFF?text=Food',
                  availableQuantity: int.tryParse(availableQuantityController.text) ?? -1,
                );
                await DataService.addMenuItem(newItem);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${newItem.name} added to menu!')),
                );
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void showEditItemDialog(MenuItem item) {
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description);
    final priceController = TextEditingController(text: item.price.toString());
    final categoryController = TextEditingController(text: item.category);
    final availableQuantityController = TextEditingController(text: item.availableQuantity == -1 ? '' : item.availableQuantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: availableQuantityController,
                decoration: InputDecoration(labelText: 'Available Quantity (leave blank for unlimited)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async { // Make onPressed async
              if (nameController.text.trim().isNotEmpty && priceController.text.isNotEmpty) {
                final updatedItem = MenuItem(
                  id: item.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  price: double.tryParse(priceController.text) ?? item.price,
                  category: categoryController.text.trim(),
                  imageUrl: item.imageUrl, // Assuming imageUrl is not edited here
                  isAvailable: item.isAvailable,
                  availableQuantity: int.tryParse(availableQuantityController.text) ?? -1,
                );
                await DataService.updateMenuItem(updatedItem);
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void showDeleteConfirmationDialog(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await DataService.removeMenuItem(item.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name} deleted.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting item: ${e.toString()}')),
                );
              }
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}