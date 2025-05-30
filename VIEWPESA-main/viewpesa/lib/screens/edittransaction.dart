import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/dbhelper.dart';
import '../models/transaction_models.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/dbhelper.dart';
import '../models/transaction_models.dart';

class ViewpesaEdittransaction extends StatefulWidget {
  const ViewpesaEdittransaction({super.key});

  @override
  State<ViewpesaEdittransaction> createState() => _ViewpesaEdittransactionState();
}

class _ViewpesaEdittransactionState extends State<ViewpesaEdittransaction> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final DBHelper _dbHelper = DBHelper();
  TransactionModel? _transaction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null) {
        _amountController.text = args['amount'].toString();
        _costController.text = args['cost'].toString();
        _balanceController.text = args['balance'].toString();
        _dateController.text = args['time'].split(' ')[0];
        _timeController.text = args['time'].split(' ')[1];
        _transaction = TransactionModel(
          id: args['transactionId'],
          type: args['type'],
          party: args['party'],
          amount: args['amount'],
          cost: args['cost'],
          balance: args['balance'],
          time: args['time'],
          tag: args['tag'],
        );
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _costController.dispose();
    _balanceController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final updatedTransaction = TransactionModel(
        id: _transaction!.id,
        type: _transaction!.type,
        party: _transaction!.party,
        amount: double.parse(_amountController.text),
        cost: double.parse(_costController.text),
        balance: double.parse(_balanceController.text),
        time: '${_dateController.text} ${_timeController.text}',
        tag: _transaction!.tag,
      );
      await _dbHelper.updateTransaction(updatedTransaction);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction Updated!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(
          "Edit Transaction",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.greenAccent[700],
      ),
      body:  GestureDetector(
    onTap: () {
    FocusScope.of(context).unfocus(); // Dismiss keyboard on tap
    },
    child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value == null || value.isEmpty ? 'Please enter amount' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _costController,
                decoration: InputDecoration(
                  labelText: 'Cost',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value == null || value.isEmpty ? 'Please enter cost' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: 'Balance',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value == null || value.isEmpty ? 'Please enter balance' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                    labelText: 'Select Date',
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)))),
                keyboardType: TextInputType.datetime,
                readOnly: true,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                  }
                },
                validator: (value) {
                  try {
                    if (value == null || value.isEmpty) return 'Enter a valid date';
                    DateFormat('yyyy-MM-dd').parseStrict(value);
                    return null;
                  } catch (_) {
                    return 'Use format: YYYY-MM-DD';
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                    labelText: 'Select Time',
                    suffixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)))),
                keyboardType: TextInputType.datetime,
                readOnly: true,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    _timeController.text = pickedTime.format(context);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter a valid time';
                  final regex = RegExp(r'^\d{1,2}:\d{2}\s?(AM|PM)?$', caseSensitive: false);
                  return regex.hasMatch(value) ? null : 'Use format: HH:MM AM/PM';
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('SAVE'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
