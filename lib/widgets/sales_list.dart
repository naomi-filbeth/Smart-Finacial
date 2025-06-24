
import 'package:flutter/material.dart';

class SalesList extends StatelessWidget {
  final List<Map<String, dynamic>> sales;

  const SalesList({super.key, required this.sales});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        final totalPrice = sale['quantity'] * sale['price'];

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.shopping_cart,
              color: Color(0xFF26A69A),
            ),
            title: Text(
              '${sale['product']} (x${sale['quantity']})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(sale['date']),
            trailing: Text(
              '\$${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF26A69A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
