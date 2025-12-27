import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _budgetController = TextEditingController();
  String _currency = '\$';

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      _budgetController.text = authProvider.currentUser!.budget.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (currentUser != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Logged in as'),
                  subtitle: Text(
                    currentUser.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'General',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: const InputDecoration(
                labelText: 'Currency',
              ),
              items: const [
                DropdownMenuItem(
                  value: '\$',
                  child: Text('USD (\$)'),
                ),
                DropdownMenuItem(
                  value: '€',
                  child: Text('EUR (€)'),
                ),
                DropdownMenuItem(
                  value: '£',
                  child: Text('GBP (£)'),
                ),
                DropdownMenuItem(
                  value: '₹',
                  child: Text('INR (₹)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currency = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (currentUser != null) ...[
              TextFormField(
                controller: _budgetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly budget',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                  helperText: 'Update your monthly budget',
                ),
                onChanged: (value) {
                  final parsed = double.tryParse(value.trim());
                  if (parsed != null && parsed >= 0) {
                    authProvider.updateUserBudget(parsed);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
            SwitchListTile(
              value: expenseProvider.isDarkMode,
              title: const Text('Dark mode'),
              secondary: const Icon(Icons.dark_mode),
              onChanged: (_) => expenseProvider.toggleDarkMode(),
            ),
            const SizedBox(height: 24),
            Text(
              'Account',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              subtitle: const Text('Sign out from your account'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout?'),
                    content: const Text('You will need to login again to access your data.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  expenseProvider.reset();
                  await authProvider.logout();
                }
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Danger zone',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Reset all data'),
              subtitle: const Text('This will delete all expenses permanently'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset all data?'),
                    content: const Text(
                      'This will delete all expenses. '
                      'This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await expenseProvider.clearAllData();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data reset')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}


