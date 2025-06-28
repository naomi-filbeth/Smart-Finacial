import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sales_provider.dart';
import '../widgets/sales_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: const Color(0xFF26A69A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Smart Financial Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authProvider.logout(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Selector<AuthProvider, String?>(
                          selector: (_, provider) => provider.userName,
                          builder: (_, userName, __) => Text(
                            userName ?? 'User',
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Total Sales',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Selector<SalesProvider, double>(
                          selector: (_, provider) => provider.totalSales,
                          builder: (_, totalSales, __) => Text(
                            'Tsh${totalSales.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF26A69A)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Total Profit',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Selector<SalesProvider, double>(
                          selector: (_, provider) => provider.totalProfit,
                          builder: (_, totalProfit, __) => Text(
                            'Tsh${totalProfit.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: totalProfit >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Recent Sales',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Selector<SalesProvider, List<Map<String, dynamic>>>(
                  selector: (_, provider) => provider.sales,
                  builder: (_, sales, __) => sales.isEmpty
                      ? const Center(
                    child: Text(
                      'No sales recorded yet. Add a product and record a sale!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                      : SalesList(sales: sales.take(5).toList()),
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