import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  void _showAddProductDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController costController = TextEditingController();
    final TextEditingController stockController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isLoading = false;
        print('Opening Add Product dialog at ${DateTime.now()}');
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Add New Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price (Tsh)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: costController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price (Tsh)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Initial Stock',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    print('Cancel button pressed at ${DateTime.now()}');
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    print('Add button pressed at ${DateTime.now()}');
                    setState(() {
                      isLoading = true;
                      errorMessage = null;
                    });

                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text.trim());
                    final cost = double.tryParse(costController.text.trim());
                    final stock = int.tryParse(stockController.text.trim());

                    if (name.isEmpty ||
                        price == null ||
                        cost == null ||
                        stock == null ||
                        price <= 0 ||
                        cost <= 0 ||
                        stock < 0) {
                      setState(() {
                        isLoading = false;
                        errorMessage = 'Please fill in all fields with valid values.';
                      });
                      print('Validation failed: $errorMessage at ${DateTime.now()}');
                      return;
                    }

                    try {
                      await Provider.of<SalesProvider>(context, listen: false)
                          .addProduct(context, name, price, cost, stock);
                      if (dialogContext.mounted) {
                        print('Product added, closing dialog at ${DateTime.now()}');
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product added successfully')),
                        );
                      } else {
                        print('Dialog context not mounted after addProduct at ${DateTime.now()}');
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        setState(() {
                          isLoading = false;
                          errorMessage = e.toString().replaceFirst('Exception: ', '');
                        });
                        print('Error adding product in InventoryScreen: $e at ${DateTime.now()}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Failed to add product: ${e.toString().replaceFirst('Exception: ', '')}')),
                        );
                        if (e.toString().contains('Session expired')) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      } else {
                        print('Dialog context not mounted on error: $e at ${DateTime.now()}');
                      }
                    } finally {
                      // Dispose controllers only after all operations
                      nameController.dispose();
                      priceController.dispose();
                      costController.dispose();
                      stockController.dispose();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      print('Add Product dialog closed at ${DateTime.now()}');
    });
  }

  void _showDeleteConfirmationDialog(BuildContext context, String productName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        print('Opening Delete Confirmation dialog for $productName at ${DateTime.now()}');
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete "$productName"? This will also remove all associated sales records.'),
          actions: [
            TextButton(
              onPressed: () {
                print('Cancel delete dialog at ${DateTime.now()}');
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await Provider.of<SalesProvider>(context, listen: false).deleteProduct(context, productName);
                  if (dialogContext.mounted) {
                    print('Product deleted, closing dialog at ${DateTime.now()}');
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product deleted successfully')),
                    );
                  } else {
                    print('Dialog context not mounted after deleteProduct at ${DateTime.now()}');
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    print('Error in delete dialog: $e at ${DateTime.now()}');
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete product: ${e.toString().replaceFirst('Exception: ', '')}')),
                    );
                    if (e.toString().contains('Session expired')) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  } else {
                    print('Dialog context not mounted on delete error: $e at ${DateTime.now()}');
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ).whenComplete(() {
      print('Delete dialog closed at ${DateTime.now()}');
    });
  }

  @override
  Widget build(BuildContext context) {
    print('InventoryScreen build at ${DateTime.now()}');
    return Scaffold(
      backgroundColor: const Color(0xFF26A69A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Inventory',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Product Stock',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Consumer<SalesProvider>(
                builder: (context, salesProvider, child) {
                  print('Consumer rebuild at ${DateTime.now()}, products: ${salesProvider.products.length}');
                  return salesProvider.products.isEmpty
                      ? const Center(
                    child: Text(
                      'No products in inventory. Add a product to get started!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: salesProvider.products.length,
                    itemBuilder: (context, index) {
                      final product = salesProvider.products[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(
                            product['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Price: Tsh${product['price'].toStringAsFixed(2)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Stock: ${product['stock']}',
                                style: TextStyle(
                                  color: product['stock'] <= 5 ? Colors.red : Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmationDialog(context, product['name']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        backgroundColor: const Color(0xFF26A69A),
        child: const Icon(Icons.add),
      ),
    );
  }
}