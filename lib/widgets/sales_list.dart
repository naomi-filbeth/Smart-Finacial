import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesList extends StatelessWidget {
  final List<Map<String, dynamic>> sales;

  const SalesList({super.key, required this.sales});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            title: Text(
              '${sale['product_name']} (x${sale['quantity']})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Date: ${dateFormat.format(sale['date'])}'),
            trailing: Text(
              'Tsh${(sale['quantity'] * sale['price']).toStringAsFixed(2)}',
              style: const TextStyle(color: Color(0xFF26A69A)),
            ),
          ),
        );
      },
    );
  }
}