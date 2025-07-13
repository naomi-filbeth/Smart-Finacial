import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/sales_event.dart';
import '../bloc/sales_state.dart';

class AddSaleScreen extends StatefulWidget {
  final VoidCallback onSaleRecorded;

  const AddSaleScreen({super.key, required this.onSaleRecorded});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  String? _selectedProduct;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _localErrorMessage = '';
  DateTime? _lastSubmission;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _costController.dispose();
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

  Future<void> _addSale(BuildContext context, SalesBloc bloc) async {
    final now = DateTime.now();
    if (_lastSubmission != null && now.difference(_lastSubmission!).inMilliseconds < 1000) {
      return;
    }
    _lastSubmission = now;

    if (bloc.state.isLoading) return;

    setState(() {
      _localErrorMessage = '';
    });

    try {
      final quantityText = _quantityController.text.trim();
      final quantity = int.tryParse(quantityText);
      final price = double.tryParse(_priceController.text.trim());
      final cost = double.tryParse(_costController.text.trim());

      if (_selectedProduct == null) {
        throw Exception('Please select a product.');
      }
      if (quantity == null || quantity <= 0) {
        throw Exception('Please enter a valid quantity greater than 0.');
      }
      if (price == null || price < 0) {
        throw Exception('Please enter a valid price.');
      }
      if (cost == null || cost < 0) {
        throw Exception('Please enter a valid cost.');
      }

      final product = bloc.state.products.firstWhere(
            (p) => p['name'] == _selectedProduct,
        orElse: () => throw Exception('Selected product not found in inventory.'),
      );

      bloc.add(AddSale(
        productId: product['id'] as int,
        quantity: quantity,
        price: price,
        cost: cost,
        date: _selectedDate,
      ));

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
    return BlocConsumer<SalesBloc, SalesState>(
      listener: (context, state) {
        if (state.errorMessage.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to record sale: ${state.errorMessage}')),
          );
          if (state.errorMessage.contains('Session expired')) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else if (!state.isLoading && _lastSubmission != null) {
          setState(() {
            _selectedProduct = null;
            _quantityController.text = '';
            _priceController.text = '';
            _costController.text = '';
            _selectedDate = DateTime.now();
            _localErrorMessage = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sale recorded successfully')),
          );
          widget.onSaleRecorded();
          _lastSubmission = null;
        }
      },
      builder: (context, state) {
        final bloc = context.read<SalesBloc>();
        return Column(
          children: [
            if (state.isLoading) const LinearProgressIndicator(),
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
                              if (state.products.isEmpty)
                                const Text(
                                  'No products available. Please add a product in the Inventory screen first.',
                                  style: TextStyle(color: Colors.red, fontSize: 14),
                                )
                              else
                                DropdownButtonFormField<String>(
                                  value: _selectedProduct,
                                  decoration: InputDecoration(
                                    labelText: 'Product',
                                    prefixIcon: const Icon(Icons.production_quantity_limits, color: Colors.grey),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                  ),
                                  items: state.products.map((product) {
                                    return DropdownMenuItem<String>(
                                      value: product['name'] as String,
                                      child: Text('${product['name']} (Stock: ${product['stock']})'),
                                    );
                                  }).toList(),
                                  onChanged: state.isLoading
                                      ? null
                                      : (value) {
                                    setState(() {
                                      _selectedProduct = value;
                                      final product = state.products.firstWhere((p) => p['name'] == value);
                                      _priceController.text = product['price'].toString();
                                      _costController.text = product['cost'].toString();
                                      _localErrorMessage = '';
                                    });
                                  },
                                  hint: const Text('Select a product'),
                                ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                enabled: !state.isLoading,
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
                              TextField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                enabled: !state.isLoading,
                                decoration: InputDecoration(
                                  labelText: 'Price (Tsh)',
                                  prefixIcon: const Icon(Icons.attach_money, color: Colors.grey),
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
                              TextField(
                                controller: _costController,
                                keyboardType: TextInputType.number,
                                enabled: !state.isLoading,
                                decoration: InputDecoration(
                                  labelText: 'Cost (Tsh)',
                                  prefixIcon: const Icon(Icons.money_off, color: Colors.grey),
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
                                      'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: state.isLoading ? null : () => _selectDate(context),
                                    child: const Text(
                                      'Change',
                                      style: TextStyle(color: Color(0xFF26A69A)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_localErrorMessage.isNotEmpty || state.errorMessage.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.error, color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _localErrorMessage.isNotEmpty
                                            ? _localErrorMessage
                                            : state.errorMessage,
                                        style: const TextStyle(color: Colors.red, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                              ElevatedButton(
                                onPressed: (state.products.isEmpty || state.isLoading)
                                    ? null
                                    : () => _addSale(context, bloc),
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
        );
      },
    );
  }
}