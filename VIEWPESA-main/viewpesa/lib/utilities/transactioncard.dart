import 'package:flutter/material.dart';
class TransactionCard extends StatelessWidget {
  final String type; // "M-PESA Received", "Sent", etc.
  final String transactionId;
  final String party;
  final double amount;
  final double cost;
  final double balance;
  final String time;
  final String tag;

  const TransactionCard({
    super.key,
    required this.type,
    required this.transactionId,
    required this.party,
    required this.amount,
    required this.cost,
    required this.balance,
    required this.time,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to EditTransaction page when the card is tapped
        Navigator.pushNamed(context, '/Edit', arguments: {
          'transactionId': transactionId,
          'type': type,
          'party': party,
          'amount': amount,
          'cost': cost,
          'balance': balance,
          'time': time,
          'tag': tag,
        });
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text("Transaction ID: $transactionId"),
              Text("Party: $party"),
              const Divider(),
              Text("Amount: KES ${amount.toStringAsFixed(2)}"),
              Text("Cost: KES ${cost.toStringAsFixed(2)}"),
              Text("Balance: KES ${balance.toStringAsFixed(2)}"),
              Text("Time: $time"),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green.shade50,
                  ),
                  child: Text(
                    tag.isNotEmpty ? tag : "Add Tag",
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
