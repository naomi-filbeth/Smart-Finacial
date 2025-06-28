import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';

class ProfitLossScreen extends StatelessWidget {
  const ProfitLossScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF26A69A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profit & Loss',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Selector<SalesProvider, bool>(
        selector: (_, provider) => provider.isLoading,
        builder: (_, isLoading, child) => isLoading
            ? const Center(child: CircularProgressIndicator())
            : child!,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          'Financial Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Sales',
                              style: TextStyle(fontSize: 16),
                            ),
                            Selector<SalesProvider, double>(
                              selector: (_, provider) => provider.totalSales,
                              builder: (_, totalSales, __) => Text(
                                'Tsh${totalSales.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF26A69A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Cost',
                              style: TextStyle(fontSize: 16),
                            ),
                            Selector<SalesProvider, double>(
                              selector: (_, provider) => provider.totalCost,
                              builder: (_, totalCost, __) => Text(
                                'Tsh${totalCost.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Profit',
                              style: TextStyle(fontSize: 16),
                            ),
                            Selector<SalesProvider, double>(
                              selector: (_, provider) => provider.totalProfit,
                              builder: (_, totalProfit, __) => Text(
                                'Tsh${totalProfit.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: totalProfit >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sales Records',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Selector<SalesProvider, List<Map<String, dynamic>>>(
                  selector: (_, provider) => provider.sales,
                  builder: (_, sales, __) => sales.isEmpty
                      ? const Center(
                    child: Text(
                      'No sales recorded yet. Start by adding a product and recording a sale!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      final totalPrice = sale['quantity'] * sale['price'];
                      final totalCost = sale['quantity'] * sale['cost'];
                      final profit = totalPrice - totalCost;

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(
                            '${sale['product']} (x${sale['quantity']})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Date: ${sale['date']}'),
                          trailing: Text(
                            'Profit: Tsh${profit.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: profit >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
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
      ),
    );
  }
}