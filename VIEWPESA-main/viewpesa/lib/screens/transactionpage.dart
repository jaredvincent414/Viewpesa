import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/dbhelper.dart';
import '../models/transaction_models.dart';
import '../utilities/transactioncard.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String selectedTag = 'All';
  double amountRange = 10000.0;
  DateTime? selectedDate;
  List<TransactionModel> transactions = [];
  List<TransactionModel> filteredTransactions = [];
  final DBHelper _dbHelper = DBHelper();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _searchController.addListener(() => _searchTransactions(_searchController.text));
  }

  Future<void> _loadTransactions() async {
    try {
      final loadedTransactions = await _dbHelper.getTransactions();
      print('Loaded ${loadedTransactions.length} transactions');
      setState(() {
        transactions = loadedTransactions;
        filteredTransactions = loadedTransactions;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading transactions')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    setState(() {
      filteredTransactions = transactions.where((t) {
        try {
          final matchesTag = selectedTag == 'All' || t.tag == selectedTag;
          final matchesAmount = t.amount <= amountRange;
          final transactionDate = DateFormat('yyyy-MM-dd').parse(t.time.split(' ')[0]);
          final matchesDate = selectedDate == null ||
              transactionDate.isAtSameMomentAs(selectedDate!) ||
              transactionDate.isAfter(selectedDate!);
          return matchesTag && matchesAmount && matchesDate;
        } catch (e) {
          print('Error filtering transaction: $e');
          return false;
        }
      }).toList();
      print('Filtered ${filteredTransactions.length} transactions');
    });
  }

  void _searchTransactions(String query) {
    setState(() {
      filteredTransactions = transactions.where((t) {
        try {
          final matchesQuery = t.party.toLowerCase().contains(query.toLowerCase()) ||
              t.tag.toLowerCase().contains(query.toLowerCase());
          final matchesTag = selectedTag == 'All' || t.tag == selectedTag;
          final matchesAmount = t.amount <= amountRange;
          final transactionDate = DateFormat('yyyy-MM-dd').parse(t.time.split(' ')[0]);
          final matchesDate = selectedDate == null ||
              transactionDate.isAtSameMomentAs(selectedDate!) ||
              transactionDate.isAfter(selectedDate!);
          return matchesQuery && matchesTag && matchesAmount && matchesDate;
        } catch (e) {
          print('Error searching transaction: $e');
          return false;
        }
      }).toList();
      print('Searched ${filteredTransactions.length} transactions');
    });
  }

  List<String> getTags() {
    final tags = transactions.map((t) => t.tag).where((tag) => tag.isNotEmpty).toSet().toList();
    return ['All', ...tags];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.greenAccent[700],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by tag or party',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Pick Date'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedTag = 'All';
                        amountRange = 10000.0;
                        selectedDate = null;
                        _searchController.clear();
                        _applyFilters();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reset Filters'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Max Amount: KES ${amountRange.toStringAsFixed(2)}'),
                        Expanded(
                          child: Slider(
                            value: amountRange,
                            min: 0,
                            max: 10000,
                            divisions: 100,
                            activeColor: Colors.greenAccent[700],
                            onChanged: (double value) {
                              setState(() {
                                amountRange = value;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tag:'),
                        DropdownButton<String>(
                          value: selectedTag,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedTag = newValue!;
                              _applyFilters();
                            });
                          },
                          items: getTags().map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filteredTransactions.isEmpty
                    ? const Center(child: Text('No transactions match your filters'))
                    : ListView.builder(
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final t = filteredTransactions[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/edit', arguments: {
                          'transactionId': t.id,
                          'type': t.type,
                          'party': t.party,
                          'amount': t.amount,
                          'cost': t.cost,
                          'balance': t.balance,
                          'time': t.time,
                          'tag': t.tag,
                        });
                      },
                      child: TransactionCard(
                        type: t.type,
                        transactionId: t.id,
                        party: t.party,
                        amount: t.amount,
                        cost: t.cost,
                        balance: t.balance,
                        time: t.time,
                        tag: t.tag,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}