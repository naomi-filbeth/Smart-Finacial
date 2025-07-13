import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/sales_event.dart';
import '../bloc/sales_state.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddProductDialog(
        onProductAdded: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully')),
          );
        },
      ),
    );
  }

  void _showUpdateProductDialog(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (dialogContext) => UpdateProductDialog(
        product: product,
        onProductUpdated: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          BlocBuilder<SalesBloc, SalesState>(
            builder: (context, state) => TextButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                context.read<SalesBloc>().add(DeleteProduct(id: id));
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted successfully')),
                );
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
      body: BlocBuilder<SalesBloc, SalesState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product List',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  state.products.isEmpty
                      ? const Center(
                    child: Text(
                      'No products recorded yet. Add a product to get started!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
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
                          subtitle: Text(
                            'Price: Tsh${product['price'].toStringAsFixed(2)}\nCost: Tsh${product['cost'].toStringAsFixed(2)}\nStock: ${product['stock']}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: state.isLoading
                                    ? null
                                    : () => _showUpdateProductDialog(context, product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: state.isLoading
                                    ? null
                                    : () => _showDeleteConfirmationDialog(
                                    context, product['id'], product['name']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (state.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        state.errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<SalesBloc, SalesState>(
        builder: (context, state) => FloatingActionButton(
          onPressed: state.isLoading ? null : () => _showAddProductDialog(context),
          backgroundColor: const Color(0xFF26A69A),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class AddProductDialog extends StatefulWidget {
  final VoidCallback onProductAdded;

  const AddProductDialog({super.key, required this.onProductAdded});

  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  String _localErrorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _addProduct(BuildContext context) {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final cost = double.tryParse(_costController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());

    if (name.isEmpty || price == null || cost == null || stock == null || price < 0 || cost < 0 || stock < 0) {
      setState(() {
        _localErrorMessage = 'Please fill in all fields with valid values.';
      });
      return;
    }

    context.read<SalesBloc>().add(AddProduct(
      name: name,
      price: price,
      cost: cost,
      stock: stock,
    ));

    Navigator.pop(context);
    widget.onProductAdded();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (Tsh)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cost (Tsh)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock',
                border: OutlineInputBorder(),
              ),
            ),
            if (_localErrorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _localErrorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            BlocBuilder<SalesBloc, SalesState>(
              builder: (context, state) {
                if (state.errorMessage.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        BlocBuilder<SalesBloc, SalesState>(
          builder: (context, state) => TextButton(
            onPressed: state.isLoading ? null : () => _addProduct(context),
            child: state.isLoading
                ? const CircularProgressIndicator()
                : const Text('Add'),
          ),
        ),
      ],
    );
  }
}

class UpdateProductDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onProductUpdated;

  const UpdateProductDialog({super.key, required this.product, required this.onProductUpdated});

  @override
  _UpdateProductDialogState createState() => _UpdateProductDialogState();
}

class _UpdateProductDialogState extends State<UpdateProductDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  String _localErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.product['name'];
    _priceController.text = widget.product['price'].toString();
    _costController.text = widget.product['cost'].toString();
    _stockController.text = widget.product['stock'].toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _updateProduct(BuildContext context) {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final cost = double.tryParse(_costController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());

    if (name.isEmpty || price == null || cost == null || stock == null || price < 0 || cost < 0 || stock < 0) {
      setState(() {
        _localErrorMessage = 'Please fill in all fields with valid values.';
      });
      return;
    }

    context.read<SalesBloc>().add(UpdateProduct(
      id: widget.product['id'],
      name: name,
      price: price,
      cost: cost,
      stock: stock,
    ));

    Navigator.pop(context);
    widget.onProductUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Product: ${widget.product['name']}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (Tsh)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cost (Tsh)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock',
                border: OutlineInputBorder(),
              ),
            ),
            if (_localErrorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _localErrorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            BlocBuilder<SalesBloc, SalesState>(
              builder: (context, state) {
                if (state.errorMessage.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        BlocBuilder<SalesBloc, SalesState>(
          builder: (context, state) => TextButton(
            onPressed: state.isLoading ? null : () => _updateProduct(context),
            child: state.isLoading
                ? const CircularProgressIndicator()
                : const Text('Update'),
          ),
        ),
      ],
    );
  }
}