import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/debtors_bloc.dart';
import '../bloc/debtors_event.dart';
import '../bloc/debtors_state.dart';

class DebtorsScreen extends StatelessWidget {
  const DebtorsScreen({super.key});

  void _showAddDebtorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddDebtorDialog(
        onDebtorAdded: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Debtor added successfully')),
          );
        },
      ),
    );
  }

  void _showUpdateDebtorDialog(BuildContext context, Map<String, dynamic> debtor) {
    showDialog(
      context: context,
      builder: (dialogContext) => UpdateDebtorDialog(
        debtor: debtor,
        onDebtorUpdated: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Debtor updated successfully')),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Debtor'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          BlocBuilder<DebtorsBloc, DebtorsState>(
            builder: (context, state) => TextButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                context.read<DebtorsBloc>().add(DeleteDebtor(id: id));
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debtor deleted successfully')),
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
          'Debtors',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: BlocBuilder<DebtorsBloc, DebtorsState>(
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
                    'Debtor List',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  state.debtors.isEmpty
                      ? const Center(
                    child: Text(
                      'No debtors recorded yet. Add a debtor to get started!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.debtors.length,
                    itemBuilder: (context, index) {
                      final debtor = state.debtors[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(
                            debtor['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Balance: Tsh${debtor['balance'].toStringAsFixed(2)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: state.isLoading
                                    ? null
                                    : () => _showUpdateDebtorDialog(context, debtor),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: state.isLoading
                                    ? null
                                    : () => _showDeleteConfirmationDialog(
                                    context, debtor['id'], debtor['name']),
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
      floatingActionButton: BlocBuilder<DebtorsBloc, DebtorsState>(
        builder: (context, state) => FloatingActionButton(
          onPressed: state.isLoading ? null : () => _showAddDebtorDialog(context),
          backgroundColor: const Color(0xFF26A69A),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class AddDebtorDialog extends StatefulWidget {
  final VoidCallback onDebtorAdded;

  const AddDebtorDialog({super.key, required this.onDebtorAdded});

  @override
  _AddDebtorDialogState createState() => _AddDebtorDialogState();
}

class _AddDebtorDialogState extends State<AddDebtorDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  String _localErrorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _productController.dispose();
    super.dispose();
  }

  void _addDebtor(BuildContext context) {
    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim());
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final product = _productController.text.trim();

    if (name.isEmpty || balance == null || balance < 0) {
      setState(() {
        _localErrorMessage = 'Please fill in name and a valid balance.';
      });
      return;
    }

    context.read<DebtorsBloc>().add(AddDebtor(
      name: name,
      balance: balance,
      email: email.isNotEmpty ? email : null,
      phone: phone,
      product: product,
    ));

    Navigator.pop(context);
    widget.onDebtorAdded();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Debtor'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Balance (Tsh)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _productController,
              decoration: const InputDecoration(
                labelText: 'Product',
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
            BlocBuilder<DebtorsBloc, DebtorsState>(
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
        BlocBuilder<DebtorsBloc, DebtorsState>(
          builder: (context, state) => TextButton(
            onPressed: state.isLoading ? null : () => _addDebtor(context),
            child: state.isLoading
                ? const CircularProgressIndicator()
                : const Text('Add'),
          ),
        ),
      ],
    );
  }
}

class UpdateDebtorDialog extends StatefulWidget {
  final Map<String, dynamic> debtor;
  final VoidCallback onDebtorUpdated;

  const UpdateDebtorDialog({super.key, required this.debtor, required this.onDebtorUpdated});

  @override
  _UpdateDebtorDialogState createState() => _UpdateDebtorDialogState();
}

class _UpdateDebtorDialogState extends State<UpdateDebtorDialog> {
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  String _localErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _balanceController.text = widget.debtor['balance'].toString();
    _emailController.text = widget.debtor['email']?.toString() ?? '';
    _phoneController.text = widget.debtor['phone']?.toString() ?? '';
    _productController.text = widget.debtor['product']?.toString() ?? '';
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _productController.dispose();
    super.dispose();
  }

  void _updateDebtor(BuildContext context) {
    final balance = double.tryParse(_balanceController.text.trim());
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final product = _productController.text.trim();

    if (balance == null || balance < 0) {
      setState(() {
        _localErrorMessage = 'Please enter a valid balance.';
      });
      return;
    }

    context.read<DebtorsBloc>().add(UpdateDebtor(
      id: widget.debtor['id'],
      balance: balance,
      email: email.isNotEmpty ? email : null,
      phone: phone,
      product: product,
    ));

    Navigator.pop(context);
    widget.onDebtorUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Debtor: ${widget.debtor['name']}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Balance (Tsh)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _productController,
              decoration: const InputDecoration(
                labelText: 'Product',
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
            BlocBuilder<DebtorsBloc, DebtorsState>(
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
        BlocBuilder<DebtorsBloc, DebtorsState>(
          builder: (context, state) => TextButton(
            onPressed: state.isLoading ? null : () => _updateDebtor(context),
            child: state.isLoading
                ? const CircularProgressIndicator()
                : const Text('Update'),
          ),
        ),
      ],
    );
  }
}