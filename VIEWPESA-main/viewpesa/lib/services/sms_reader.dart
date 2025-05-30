import 'package:telephony/telephony.dart';
import '../models/transaction_models.dart';
import 'package:intl/intl.dart';
import '../database/dbhelper.dart';

class SmsReader {
  final Telephony telephony = Telephony.instance;
  final DBHelper _dbHelper = DBHelper();

  Future<void> initSmsListener() async {
    final bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted != true) {
      throw Exception('SMS permissions not granted');
    }

    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        if (message.address?.contains('MPESA') ?? false) {
          final transaction = _parseMpesaSms(message.body);
          if (transaction != null) {
            _dbHelper.insertTransaction(transaction);
          }
        }
      },
      listenInBackground: true,
    );
  }

  Future<List<TransactionModel>> readMpesaTransactions() async {
    try {
      final bool? permissionsGranted = await telephony.requestSmsPermissions;
      if (permissionsGranted != true) {
        throw Exception('SMS permissions not granted');
      }

      final List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals('MPESA'),
      );

      print('Retrieved ${messages.length} SMS messages');
      List<TransactionModel> transactions = [];
      for (var msg in messages) {
        final transaction = _parseMpesaSms(msg.body);
        if (transaction != null) {
          transactions.add(transaction);
          await _dbHelper.insertTransaction(transaction);
        }
      }
      print('Parsed ${transactions.length} transactions');
      return transactions;
    } catch (e, stackTrace) {
      print('Error reading SMS: $e\n$stackTrace');
      throw Exception('Failed to read SMS: $e');
    }
  }

  TransactionModel? _parseMpesaSms(String? body) {
    if (body == null) return null;

    final regex = RegExp(
      r'(\w+\d+\w*) Confirmed\.\s*(?:You have received|Sent|Give|Paid|(?:Bought|Withdrawn))?\s*(?:KES)?([\d,\.]+)\s*(?:from|to|for|at)?\s*([A-Za-z\s\d]+?)?\s*(?:\+254\d{9}|\d{10})?\s*(?:on)?\s*(\d{1,2}/\d{1,2}/\d{2,4})\s*at\s*(\d{1,2}:\d{2}\s*(?:AM|PM))?(?:.*?New M-PESA balance is KES([\d,\.]+))?(?:.*?Transaction cost, KES([\d,\.]+))?',
      caseSensitive: false,
    );

    final match = regex.firstMatch(body);
    if (match != null) {
      final id = match[1] ?? 'SMS_${body.hashCode}';
      final amountStr = match[2]!.replaceAll(',', '');
      final amount = double.tryParse(amountStr) ?? 0.0;
      final party = match[3]?.trim() ?? 'Unknown';
      final date = match[4]!;
      final time = match[5] ?? DateFormat('hh:mm a').format(DateTime.now());
      final balanceStr = match[6]?.replaceAll(',', '') ?? '0.0';
      final balance = double.tryParse(balanceStr) ?? 0.0;
      final costStr = match[7]?.replaceAll(',', '') ?? '0.0';
      final cost = double.tryParse(costStr) ?? 0.0;

      String type;
      if (RegExp('received', caseSensitive: false).hasMatch(body)) {
        type = 'M-PESA Received';
      } else if (RegExp('sent', caseSensitive: false).hasMatch(body)) {
        type = 'Sent';
      } else if (RegExp('paid', caseSensitive: false).hasMatch(body)) {
        type = 'Paid';
      } else if (RegExp('bought', caseSensitive: false).hasMatch(body)) {
        type = 'Airtime';
      } else if (RegExp('withdrawn', caseSensitive: false).hasMatch(body)) {
        type = 'Withdrawn';
      } else if (RegExp('give', caseSensitive: false).hasMatch(body)) {
        type = 'Give';
      } else {
        type = 'Unknown';
      }

      return TransactionModel(
        id: id,
        type: type,
        party: party,
        amount: amount,
        cost: cost,
        balance: balance,
        time: '$date $time',
        tag: '',
      );
    }

    final reversalRegex = RegExp(
      r'(\w+\d+\w*) Reversed\.\s*(?:KES)?([\d,\.]+)\s*(?:from|to)?\s*([A-Za-z\s\d]+?)?\s*(?:on)?\s*(\d{1,2}/\d{1,2}/\d{2,4})\s*at\s*(\d{1,2}:\d{2}\s*(?:AM|PM))?',
      caseSensitive: false,
    );
    final reversalMatch = reversalRegex.firstMatch(body);
    if (reversalMatch != null) {
      final amountStr = reversalMatch[2]!.replaceAll(',', '');
      return TransactionModel(
        id: reversalMatch[1]!,
        type: 'Reversed',
        party: reversalMatch[3]?.trim() ?? 'Unknown',
        amount: double.tryParse(amountStr) ?? 0.0,
        cost: 0.0,
        balance: 0.0,
        time: '${reversalMatch[4]} ${reversalMatch[5] ?? DateFormat('hh:mm a').format(DateTime.now())}',
        tag: '',
      );
    }

    return null;
  }
}