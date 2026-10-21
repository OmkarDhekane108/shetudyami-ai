import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  String get _key =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  void _change(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('milkEntries')
        .where('date', isGreaterThanOrEqualTo: '$_key-01')
        .where('date', isLessThanOrEqualTo: '$_key-31');

    return Scaffold(
      appBar: AppBar(title: const Text('महिना हिशोब')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left, size: 32),
                    onPressed: () => _change(-1)),
                Text(_key,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.chevron_right, size: 32),
                    onPressed: () => _change(1)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final days = <String, List<double>>{};
                double totalL = 0, totalA = 0;
                for (final d in snap.data!.docs) {
                  final m = d.data() as Map<String, dynamic>;
                  final l = (m['litres'] ?? 0).toDouble();
                  final a = (m['amount'] ?? 0).toDouble();
                  final date = m['date'] as String;
                  days.putIfAbsent(date, () => [0, 0]);
                  days[date]![0] += l;
                  days[date]![1] += a;
                  totalL += l;
                  totalA += a;
                }
                final keys = days.keys.toList()..sort((a, b) => b.compareTo(a));
                return Column(
                  children: [
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(children: [
                              const Text('एकूण दूध'),
                              Text('${totalL.toStringAsFixed(1)} लि.',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                            ]),
                            Column(children: [
                              const Text('एकूण रक्कम'),
                              Text('₹${totalA.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: keys.isEmpty
                          ? const Center(child: Text('या महिन्यात नोंद नाही'))
                          : ListView.separated(
                              itemCount: keys.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final k = keys[i];
                                return ListTile(
                                  title: Text(k,
                                      style: const TextStyle(fontSize: 18)),
                                  subtitle: Text(
                                      '${days[k]![0].toStringAsFixed(1)} लि.'),
                                  trailing: Text(
                                      '₹${days[k]![1].toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 18)),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}