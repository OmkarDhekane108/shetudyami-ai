import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MilkScreen extends StatefulWidget {
  const MilkScreen({super.key});

  @override
  State<MilkScreen> createState() => _MilkScreenState();
}

class _MilkScreenState extends State<MilkScreen> {
  final _litres = TextEditingController();
  final _fat = TextEditingController();
  final _rate = TextEditingController(text: '40');
  String _session = 'सकाळ';
  bool _saving = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _col => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('milkEntries');

  double get _amount {
    final l = double.tryParse(_litres.text) ?? 0;
    final r = double.tryParse(_rate.text) ?? 0;
    return l * r;
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    final l = double.tryParse(_litres.text);
    final r = double.tryParse(_rate.text);
    if (l == null || r == null || l <= 0) return;
    setState(() => _saving = true);
    await _col.add({
      'date': _today(),
      'session': _session,
      'litres': l,
      'fat': double.tryParse(_fat.text) ?? 0,
      'rate': r,
      'amount': l * r,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _litres.clear();
    _fat.clear();
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('दूध नोंद')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'सकाळ', label: Text('सकाळ')),
              ButtonSegment(value: 'संध्याकाळ', label: Text('संध्याकाळ')),
            ],
            selected: {_session},
            onSelectionChanged: (s) => setState(() => _session = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _litres,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 20),
            decoration: const InputDecoration(
                labelText: 'लिटर', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fat,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20),
            decoration: const InputDecoration(
                labelText: 'फॅट', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rate,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 20),
            decoration: const InputDecoration(
                labelText: 'दर (₹/लिटर)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Text('रक्कम: ₹${_amount.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('सेव्ह करा', style: TextStyle(fontSize: 20)),
            ),
          ),
          const Divider(height: 40),
          const Text('आजच्या नोंदी',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          StreamBuilder<QuerySnapshot>(
            stream: _col.where('date', isEqualTo: _today()).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()));
              }
              final docs = snap.data!.docs;
              double totalL = 0, totalA = 0;
              for (final d in docs) {
                final m = d.data() as Map<String, dynamic>;
                totalL += (m['litres'] ?? 0).toDouble();
                totalA += (m['amount'] ?? 0).toDouble();
              }
              return Column(
                children: [
                  for (final d in docs)
                    Builder(builder: (_) {
                      final m = d.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text('${m['session']}: ${m['litres']} लि.'),
                        subtitle: Text('फॅट ${m['fat']}  |  दर ₹${m['rate']}'),
                        trailing: Text('₹${m['amount']}',
                            style: const TextStyle(fontSize: 18)),
                      );
                    }),
                  const Divider(),
                  Text(
                      'एकूण: ${totalL.toStringAsFixed(1)} लि.  |  ₹${totalA.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}