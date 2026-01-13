// lib/screens/expenses/add_expense_screen.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/app_models.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseGroup group;
  final List<AppUser> members;

  const AddExpenseScreen({
    Key? key,
    required this.group,
    required this.members,
  }) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _paidBy;
  Set<String> _splitBetween = {};
  SplitType _splitType = SplitType.equal;
  int _selectedCategory = 0;
  bool _isLoading = false;

  // For custom split amounts
  Map<String, TextEditingController> _customControllers = {};

  @override
  void initState() {
    super.initState();
    _paidBy = _authService.currentUser?.uid;
    _splitBetween = widget.members.map((m) => m.uid).toSet();

    // Initialize custom controllers
    for (final member in widget.members) {
      _customControllers[member.uid] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _addExpense() async {
    if (_amountController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    if (_splitBetween.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one person')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text);
    final splitDetails = _calculateSplitDetails(amount);

    final expenseId = await _firestoreService.addExpense(
      groupId: widget.group.id,
      amount: amount,
      description: _descriptionController.text.trim(),
      category: ExpenseCategory.defaultCategories[_selectedCategory].name,
      paidBy: _paidBy!,
      splitBetween: _splitBetween.toList(),
      splitType: _splitType,
      splitDetails: splitDetails,
    );

    if (expenseId != null && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense added! 💰'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _isLoading = false);
    }
  }

  Map<String, double> _calculateSplitDetails(double amount) {
    final details = <String, double>{};

    switch (_splitType) {
      case SplitType.equal:
        final perPerson = amount / _splitBetween.length;
        for (final userId in _splitBetween) {
          details[userId] = double.parse(perPerson.toStringAsFixed(2));
        }
        break;

      case SplitType.exact:
        for (final userId in _splitBetween) {
          final text = _customControllers[userId]?.text ?? '0';
          details[userId] = double.tryParse(text) ?? 0;
        }
        break;

      case SplitType.percentage:
        for (final userId in _splitBetween) {
          final text = _customControllers[userId]?.text ?? '0';
          final percentage = double.tryParse(text) ?? 0;
          details[userId] = double.parse((amount * percentage / 100).toStringAsFixed(2));
        }
        break;

      case SplitType.shares:
        final totalShares = _splitBetween.fold<double>(0, (sum, userId) {
          final text = _customControllers[userId]?.text ?? '1';
          return sum + (double.tryParse(text) ?? 1);
        });
        for (final userId in _splitBetween) {
          final text = _customControllers[userId]?.text ?? '1';
          final shares = double.tryParse(text) ?? 1;
          details[userId] = double.parse((amount * shares / totalShares).toStringAsFixed(2));
        }
        break;
    }

    return details;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ExpenseCategory.defaultCategories;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3E8FF), Color(0xFFFCE7F3), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Add Expense 💰',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(categories.length, (index) {
                          final cat = categories[index];
                          final isSelected = index == _selectedCategory;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Color(int.parse(cat.colorHex.substring(1), radix: 16) + 0xFF000000)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Text(
                                    cat.name,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 24),

                      // Amount & Description
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                prefixText: '₹ ',
                                hintText: '0',
                                border: InputBorder.none,
                              ),
                            ),
                            const Divider(),
                            TextField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                hintText: 'What\'s this for?',
                                border: InputBorder.none,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Paid by
                      const Text(
                        'Paid by',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: widget.members.map((member) {
                            final isSelected = _paidBy == member.uid;
                            return RadioListTile<String>(
                              value: member.uid,
                              groupValue: _paidBy,
                              onChanged: (value) => setState(() => _paidBy = value),
                              title: Row(
                                children: [
                                  Text(member.avatar, style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 12),
                                  Text(member.name),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Split Type
                      const Text(
                        'Split Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildSplitTypeOption(SplitType.equal, '= Equally', 'Split amount equally'),
                            _buildSplitTypeOption(SplitType.exact, '₹ Exact Amounts', 'Enter exact amount for each'),
                            _buildSplitTypeOption(SplitType.percentage, '% Percentages', 'Split by percentage'),
                            _buildSplitTypeOption(SplitType.shares, '# Shares', 'Split by shares'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Split Between
                      const Text(
                        'Split between',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: widget.members.map((member) {
                            final isSelected = _splitBetween.contains(member.uid);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value!) {
                                    _splitBetween.add(member.uid);
                                  } else {
                                    _splitBetween.remove(member.uid);
                                  }
                                });
                              },
                              title: Row(
                                children: [
                                  Text(member.avatar, style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(member.name)),
                                  if (_splitType != SplitType.equal && isSelected)
                                    SizedBox(
                                      width: 80,
                                      child: TextField(
                                        controller: _customControllers[member.uid],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          hintText: _splitType == SplitType.percentage
                                              ? '%'
                                              : _splitType == SplitType.shares
                                              ? '1'
                                              : '₹',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Split Preview
                      if (_amountController.text.isNotEmpty && _splitBetween.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Split Preview:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._calculateSplitDetails(double.tryParse(_amountController.text) ?? 0)
                                    .entries
                                    .map((entry) {
                                  final member = widget.members.firstWhere((m) => m.uid == entry.key);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${member.avatar} ${member.name}'),
                                        Text(
                                          '₹${entry.value.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Add Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Add Expense 🚀',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitTypeOption(SplitType type, String title, String subtitle) {
    final isSelected = _splitType == type;
    return RadioListTile<SplitType>(
      value: type,
      groupValue: _splitType,
      onChanged: (value) => setState(() => _splitType = value!),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    );
  }
}