import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/debtors_provider.dart';

class DebtorsScreen extends StatelessWidget {
  const DebtorsScreen({super.key});

  void _showAddDebtorDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController balanceController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Debtor'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Debtor Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Balance Owed',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Address (Optional)',
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final balance = double.tryParse(balanceController.text.trim());
                    final email = emailController.text.trim();
                    final phone = phoneController.text.trim();
                    final address = addressController.text.trim();

                    if (name.isEmpty || balance == null || balance <= 0) {
                      setState(() {
                        errorMessage = 'Please fill in name and valid balance.';
                      });
                      return;
                    }

                    try {
                      await Provider.of<DebtorsProvider>(context, listen: false).addDebtor(
                        name,
                        balance,
                        email: email.isNotEmpty ? email : null,
                        phone: phone.isNotEmpty ? phone : null,
                        address: address.isNotEmpty ? address : null,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Debtor added successfully')),
                      );
                    } catch (e) {
                      setState(() {
                        errorMessage = e.toString().replaceFirst('Exception: ', '');
                      });
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDebtorDialog(BuildContext context, Map<String, dynamic> debtor) {
    final TextEditingController balanceController = TextEditingController(text: debtor['balance']?.toString() ?? '0.00');
    final TextEditingController emailController = TextEditingController(text: debtor['email']?.toString() ?? '');
    final TextEditingController phoneController = TextEditingController(text: debtor['phone']?.toString() ?? '');
    final TextEditingController addressController = TextEditingController(text: debtor['address']?.toString() ?? '');
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Debtor: ${debtor['name']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Balance Owed',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Address (Optional)',
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final balance = double.tryParse(balanceController.text.trim());
                    final email = emailController.text.trim();
                    final phone = phoneController.text.trim();
                    final address = addressController.text.trim();

                    if (balance == null || balance <= 0) {
                      setState(() {
                        errorMessage = 'Please provide a valid balance.';
                      });
                      return;
                    }

                    try {
                      await Provider.of<DebtorsProvider>(context, listen: false).updateDebtor(
                        debtor['id'] as int,
                        balance,
                        email: email.isNotEmpty ? email : null,
                        phone: phone.isNotEmpty ? phone : null,
                        address: address.isNotEmpty ? address : null,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Debtor updated successfully')),
                      );
                    } catch (e) {
                      setState(() {
                        errorMessage = e.toString().replaceFirst('Exception: ', '');
                      });
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String debtorName, int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Debtor'),
          content: Text('Are you sure you want to delete "$debtorName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await Provider.of<DebtorsProvider>(context, listen: false).deleteDebtor(id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debtor deleted successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete debtor: ${e.toString().replaceFirst('Exception: ', '')}')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final debtorsProvider = Provider.of<DebtorsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF26A69A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Debtors',
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
                'Debtor List',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              debtorsProvider.debtors.isEmpty
                  ? const Center(
                child: Text(
                  'No debtors recorded yet. Add a debtor to get started!',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: debtorsProvider.debtors.length,
                itemBuilder: (context, index) {
                  final debtor = debtorsProvider.debtors[index];
                  final balanceStr = debtor['balance']?.toString() ?? '0.00';
                  final balance = double.tryParse(balanceStr) ?? 0.0; // Convert String to num
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        debtor['name']?.toString() ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Balance: Tsh ${balance.toStringAsFixed(2)}'),
                          if (debtor['email'] != null) Text('Email: ${debtor['email']}'),
                          if (debtor['phone'] != null) Text('Phone: ${debtor['phone']}'),
                          if (debtor['address'] != null) Text('Address: ${debtor['address']}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tsh${balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF26A69A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditDebtorDialog(context, debtor),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmationDialog(context, debtor['name']?.toString() ?? 'Unknown', debtor['id'] as int),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtorDialog(context),
        backgroundColor: const Color(0xFF26A69A),
        child: const Icon(Icons.add),
      ),
    );
  }
}