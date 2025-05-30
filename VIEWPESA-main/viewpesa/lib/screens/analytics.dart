import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/dbhelper.dart';
import '../models/transaction_models.dart';
import '../utilities/transactioncard.dart';

class ViewpesaAnalysis extends StatefulWidget {
  const ViewpesaAnalysis({super.key});

  @override
  State<ViewpesaAnalysis> createState() => _ViewpesaAnalysisState();
}

class _ViewpesaAnalysisState extends State<ViewpesaAnalysis> {
  final TextEditingController _searchController = TextEditingController();
  int _expandedIndex = -1;
  List<TransactionModel> _transactions = [];
  final DBHelper _dbHelper = DBHelper();
  double _currentBalance = 5000.0;
  double _totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(() {
      _searchTransactions(_searchController.text);
    });
  }

  Future<void> _initializeData() async {
    try {
      await _dbHelper.insertTestTransaction(); // Insert test data (remove in production)
      final transactions = await _dbHelper.getTransactions();
      print('Loaded ${transactions.length} transactions'); // Debug

      setState(() {
        _transactions = transactions;
        _totalSpent = transactions.fold(
          0.0, (sum, t) => sum + (t.type == 'Sent' ? t.amount : 0.0),
        );
        _currentBalance = transactions.fold(
          0.0,
              (sum, t) => sum +
              (t.type == 'M-PESA Received'
                  ? t.amount
                  : -t.amount),
        );
      });
    } catch (e) {
      print('Error loading transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading transactions')),
        );
      }
    }
  }
  bool _isLoading = false;

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });
    try {
      final transactions = await _dbHelper.getTransactions();
      print('Loaded ${transactions.length} transactions');
      setState(() {
        _transactions = transactions;
        // Calculate total spent for 'Sent' transactions
        _totalSpent = transactions.fold(
          0.0,
              (sum, t) => sum + (t.type == 'Sent' ? t.amount : 0.0),
        );
        // Calculate balance considering multiple transaction types
        _currentBalance = transactions.fold(
          0.0,
              (sum, t) {
            switch (t.type) {
              case 'M-PESA Received':
                return sum + t.amount;
              case 'Sent':
              case 'Paid':
              case 'Withdrawn':
                return sum - t.amount;
              case 'Reversed':
              // Handle reversals based on context (e.g., reverse a previous deduction)
                return sum + t.amount; // Assuming reversal adds back the amount
              default:
                return sum; // Ignore unknown types
            }
          },
        );
      });
    } catch (e, stackTrace) {
      print('Error loading transactions: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load transactions')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }


  Future<void> _searchTransactions(String query) async {
    if (query.isEmpty) {
      await _loadTransactions();
    } else {
      final transactions = await _dbHelper.searchTransactions(query);
      setState(() {
        _transactions = transactions;
      });
    }
  }

  void _handleCardTap(int index) {
    setState(() {
      _expandedIndex = (_expandedIndex == index) ? -1 : index;
    });
  }

  Map<String, double> _aggregateByTag() {
    final Map<String, double> tagTotals = {};
    for (var t in _transactions) {
      tagTotals[t.tag] = (tagTotals[t.tag] ?? 0) + t.amount;
    }
    return tagTotals;
  }

  List<FlSpot> _aggregateByDate() {
    final Map<String, double> dateTotals = {};
    for (var t in _transactions) {
      final date = t.time.split(' ')[0];
      dateTotals[date] = (dateTotals[date] ?? 0) + t.amount;
    }
    final sortedDates = dateTotals.keys.toList()..sort();
    return sortedDates.asMap().entries.map((e) => FlSpot(e.key.toDouble(), dateTotals[e.value]!)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tagTotals = _aggregateByTag();
    final dateSpots = _aggregateByDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.greenAccent[700],
      ),
      body:
      _isLoading
          ? const Center(child: CircularProgressIndicator())
      :ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Search Transactions",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "e.g. yesterday, groceries, last week...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildBalanceCard("Current Balance", "KES ${_currentBalance.toStringAsFixed(2)}"),
              const SizedBox(width: 10),
              _buildBalanceCard("Total Spent", "KES ${_totalSpent.toStringAsFixed(2)}"),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text('No transactions available'))
                : ListView(
              children: _transactions.map((t) => TransactionCard(
                type: t.type,
                transactionId: t.id,
                party: t.party,
                amount: t.amount,
                cost: t.cost,
                balance: t.balance,
                time: t.time,
                tag: t.tag,
              )).toList(),
            ),
          ),

          const SizedBox(height: 20),
          _buildAnimatedChartCard(0, "Bar Graph", BarChart(
            BarChartData(
              barGroups: tagTotals.entries.toList().asMap().entries.map((e) => BarChartGroupData(
                x: e.key,
                barRods: [BarChartRodData(toY: e.value.value, color: Colors.greenAccent[700])],
              )).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(tagTotals.keys.elementAt(value.toInt())),
                  ),
                ),
              ),
            ),
          )),
          _buildAnimatedChartCard(1, "Pie Chart", PieChart(
            PieChartData(
              sections: tagTotals.entries.toList().asMap().entries.map((e) => PieChartSectionData(
                value: e.value.value,
                title: e.value.key,
                color: Colors.primaries[e.key % Colors.primaries.length],
              )).toList(),
            ),
          )),
          _buildAnimatedChartCard(2, "Line Graph", LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: dateSpots,
                  color: Colors.greenAccent[700],
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(
                      _transactions[value.toInt()].time.split(' ')[0],
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String title, String amount) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(amount, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedChartCard(int index, String label, Widget chart) {
    final bool isExpanded = _expandedIndex == index;
    return GestureDetector(
      onTap: () => _handleCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        height: isExpanded ? 220 : 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isExpanded ? 18 : 14,
                  fontWeight: isExpanded ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Expanded(child: chart),
          ],
        ),
      ),
    );
  }
}

