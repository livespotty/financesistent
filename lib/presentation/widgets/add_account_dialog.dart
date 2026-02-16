import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/account.dart';
import '../../providers/providers.dart';

/// A dialog that allows users to create a new financial account.
/// Collects account name, type, role, opening balance, and currency.
class AddAccountDialog extends ConsumerStatefulWidget {
  /// The existing account to edit, if any.
  final Account? account;

  /// Creates a new [AddAccountDialog] instance.
  const AddAccountDialog({super.key, this.account});

  @override
  ConsumerState<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  final _notesController = TextEditingController();
  
  AccountType _selectedType = AccountType.asset;
  AccountRole? _selectedRole;
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _openingBalanceController.text = widget.account!.openingBalance.toString();
      _notesController.text = widget.account!.notes ?? '';
      _selectedType = widget.account!.type;
      _selectedRole = widget.account!.role;
      _selectedCurrency = widget.account!.currencyCode;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _openingBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final openingBalance = double.tryParse(_openingBalanceController.text) ?? 0.0;
      
      if (widget.account != null) {
        // Edit existing
        final updatedAccount = widget.account!.copyWith(
          name: _nameController.text,
          type: _selectedType,
          role: _selectedRole,
          currencyCode: _selectedCurrency,
          openingBalance: openingBalance,
          // Calculate new current balance by adjusting with delta of opening balance
          currentBalance: widget.account!.currentBalance + (openingBalance - widget.account!.openingBalance),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
        ref.read(accountsProvider.notifier).updateAccount(updatedAccount);
      } else {
        // Create new
        final account = Account(
          id: const Uuid().v4(),
          name: _nameController.text,
          type: _selectedType,
          role: _selectedRole,
          currencyCode: _selectedCurrency,
          currentBalance: openingBalance,
          openingBalance: openingBalance,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          active: true,
          createdAt: DateTime.now(),
        );
        ref.read(accountsProvider.notifier).addAccount(account);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.account != null ? 'Edit Account' : 'Add New Account',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12),
                      child: FaIcon(FontAwesomeIcons.tag, size: 18),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AccountType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Account Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(12),
                            child: FaIcon(FontAwesomeIcons.list, size: 18),
                          ),
                        ),
                        items: AccountType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                              _selectedRole = null; // Reset role when type changes
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<AccountRole>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Account Role',
                          border: OutlineInputBorder(),
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(12),
                            child: FaIcon(FontAwesomeIcons.userTie, size: 18),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<AccountRole>(
                            value: null,
                            child: Text('NONE'),
                          ),
                          ...AccountRole.values.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.name.toUpperCase()),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _openingBalanceController,
                        decoration: const InputDecoration(
                          labelText: 'Opening Balance',
                          border: OutlineInputBorder(),
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(12),
                            child: FaIcon(FontAwesomeIcons.moneyBill, size: 18),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          border: OutlineInputBorder(),
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(12),
                            child: FaIcon(FontAwesomeIcons.dollarSign, size: 18),
                          ),
                        ),
                        items: ['USD', 'EUR', 'GBP', 'JPY', 'CAD'].map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCurrency = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12),
                      child: FaIcon(FontAwesomeIcons.noteSticky, size: 18),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(widget.account != null ? 'Save Changes' : 'Add Account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
