import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final costController = TextEditingController();
    final stockController = TextEditingController();
    String localErrorMessage = '';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
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
                if (localErrorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      localErrorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                Selector<SalesProvider, String>(
                  selector: (_, provider) => provider.errorMessage,
                  builder: (_, errorMessage, __) => errorMessage.isNotEmpty
                      ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            Selector<SalesProvider, bool>(
              selector: (_, provider) => provider.isLoading,
              builder: (_, isLoading, __) => TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                  final name = nameController.text.trim();
                  final price = double.tryParse(priceController.text.trim());
                  final cost = double.tryParse(costController.text.trim());
                  final stock = int.tryParse(stockController.text.trim());

                  if (name.isEmpty || price == null || cost == null || stock == null || price <= 0 || cost <= 0 || stock < 0) {
                    setState(() {
                      localErrorMessage = 'Please fill in all fields with valid values.';
                    });
                    return;
                  }

                  try {
                    await Provider.of<SalesProvider>(context, listen: false).addProduct(context, name, price, cost, stock);
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product added successfully')),
                    );
                  } catch (e) {
                    setState(() {
                      localErrorMessage = e.toString().replaceFirst('Exception: ', '');
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add product: $localErrorMessage')),
                    );
                    if (e.toString().contains('Session expired')) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  }
                },
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      nameController.dispose();
      priceController.dispose();
      costController.dispose();
      stockController.dispose();
    });
  }

  void _showDeleteConfirmationDialog(BuildContext context, String productName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$productName"? This will also remove all associated sales records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          Selector<SalesProvider, bool>(
            selector: (_, provider) => provider.isLoading,
            builder: (_, isLoading, __) => TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                try {
                  await Provider.of<SalesProvider>(context, listen: false).deleteProduct(context, productName);
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product deleted successfully')),
                  );
                } catch (e) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete product: ${e.toString().replaceFirst('Exception: ', '')}')),
                  );
                  if (e.toString().contains('Session expired')) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              Selector<SalesProvider, bool>(
                selector: (_, provider) => provider.isLoading,
                builder: (_, isLoading, child) => isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : child!,
                child: Selector<SalesProvider, List<Map<String, dynamic>>>(
                  selector: (_, provider) => provider.products,
                  builder: (_, products, __) => products.isEmpty
                      ? const Center(
                    child: Text(
                      'No products in inventory. Add a product to get started!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
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
                              Selector<SalesProvider, bool>(
                                selector: (_, provider) => provider.isLoading,
                                builder: (_, isLoading, __) => IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: isLoading ? null : () => _showDeleteConfirmationDialog(context, product['name']),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Selector<SalesProvider, String>(
                selector: (_, provider) => provider.errorMessage,
                builder: (_, errorMessage, __) => errorMessage.isNotEmpty
                    ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Selector<SalesProvider, bool>(
        selector: (_, provider) => provider.isLoading,
        builder: (_, isLoading, __) => FloatingActionButton(
          onPressed: isLoading ? null : () => _showAddProductDialog(context),
          backgroundColor: const Color(0xFF26A69A),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}