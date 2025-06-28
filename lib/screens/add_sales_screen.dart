import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';

class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({super.key, required this.onSaleRecorded});

  final VoidCallback onSaleRecorded;

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  String _selectedProduct = '';
  final TextEditingController _quantityController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _localErrorMessage = '';
  DateTime? _lastSubmission;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null && picked != _selectedDate && mounted) {
        setState(() {
          _selectedDate = picked;
          _localErrorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localErrorMessage = 'Error selecting date: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _addSale(BuildContext context, SalesProvider provider) async {
    final now = DateTime.now();
    if (_lastSubmission != null && now.difference(_lastSubmission!).inMilliseconds < 1000) {
      return;
    }
    _lastSubmission = now;

    if (provider.isLoading) return;

    setState(() {
      _localErrorMessage = '';
    });

    try {
      final quantityText = _quantityController.text.trim();
      final quantity = int.tryParse(quantityText);

      if (_selectedProduct.isEmpty) {
        throw Exception('Please select a product.');
      }
      if (quantity == null || quantity <= 0) {
        throw Exception('Please enter a valid quantity greater than 0.');
      }

      final product = provider.products.firstWhere(
            (p) => p['name'] == _selectedProduct,
        orElse: () => throw Exception('Selected product not found in inventory.'),
      );

      await provider.addSale(context, {
        'product': _selectedProduct,
        'quantity': quantity,
        'price': product['price'] as double,
        'date': _selectedDate.toString().split(' ')[0],
      });

      if (mounted) {
        setState(() {
          _selectedProduct = '';
          _quantityController.text = '';
          _selectedDate = DateTime.now();
          _localErrorMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale recorded successfully')),
        );
        widget.onSaleRecorded();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localErrorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record sale: $_localErrorMessage')),
        );
        if (e.toString().contains('Session expired')) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, provider, child) => Column(
        children: [
          if (provider.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      title: const Text(
                        'Add Sale',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'New Sale',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (provider.products.isEmpty)
                              const Text(
                                'No products available. Please add a product in the Inventory screen first.',
                                style: TextStyle(color: Colors.red, fontSize: 14),
                              )
                            else
                              DropdownButtonFormField<String>(
                                value: _selectedProduct.isEmpty ? null : _selectedProduct,
                                decoration: InputDecoration(
                                  labelText: 'Product',
                                  prefixIcon: const Icon(Icons.production_quantity_limits, color: Colors.grey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                items: provider.products.map((product) {
                                  return DropdownMenuItem<String>(
                                    value: product['name'],
                                    child: Text('${product['name']} (Stock: ${product['stock']})'),
                                  );
                                }).toList(),
                                onChanged: provider.isLoading
                                    ? null
                                    : (value) {
                                  setState(() {
                                    _selectedProduct = value ?? '';
                                    _localErrorMessage = '';
                                  });
                                },
                                hint: const Text('Select a product'),
                              ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              enabled: !provider.isLoading,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                prefixIcon: const Icon(Icons.numbers, color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _localErrorMessage = '';
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Date: ${_selectedDate.toString().split(' ')[0]}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                TextButton(
                                  onPressed: provider.isLoading ? null : () => _selectDate(context),
                                  child: const Text(
                                    'Change',
                                    style: TextStyle(color: Color(0xFF26A69A)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_localErrorMessage.isNotEmpty || provider.errorMessage.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(Icons.error, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _localErrorMessage.isNotEmpty
                                          ? _localErrorMessage
                                          : provider.errorMessage,
                                      style: const TextStyle(color: Colors.red, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            ElevatedButton(
                              onPressed: (provider.products.isEmpty || provider.isLoading)
                                  ? null
                                  : () => _addSale(context, provider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF26A69A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              ),
                              child: const Text('Record Sale', style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}