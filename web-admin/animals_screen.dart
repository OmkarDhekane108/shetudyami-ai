import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnimalsScreen extends StatelessWidget {
  const AnimalsScreen({super.key});

  CollectionReference get _col => FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('animals');

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _add(BuildContext context) async {
    final name = TextEditingController();
    final tag = TextEditingController();
    String type = 'गाय';
    DateTime? due;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('नवीन जनावर'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'गाय', label: Text('गाय')),
                    ButtonSegment(value: 'म्हैस', label: Text('म्हैस')),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) => setS(() => type = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: name,
                    decoration: const InputDecoration(
                        labelText: 'नाव', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: tag,
                    decoration: const InputDecoration(
                        labelText: 'टॅग नंबर', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.vaccines),
                  label: Text(due == null
                      ? 'पुढील लसीकरण तारीख'
                      : _fmt(due!)),
                  onPressed: () async {
                    final p = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 180)),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (p != null) setS(() => due = p);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('रद्द')),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await _col.add({
                  'name': name.text.trim(),
                  'type': type,
                  'tag': tag.text.trim(),
                  'nextVaccination': due == null ? '' : _fmt(due!),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('सेव्ह'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('जनावरे ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('जनावर जोडा'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _col.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('अजून जनावर जोडले नाही'));
          }
          final today = DateTime.now();
          return ListView(
            padding: const EdgeInsets.only(bottom: 90),
            children: [
              for (final d in docs)
                Builder(builder: (_) {
                  final m = d.data() as Map<String, dynamic>;
                  final dueStr = (m['nextVaccination'] ?? '') as String;
                  String status = 'लसीकरण तारीख नाही';
                  Color color = Colors.grey;
                  if (dueStr.isNotEmpty) {
                    final days = DateTime.parse(dueStr)
                        .difference(DateTime(today.year, today.month, today.day))
                        .inDays;
                    if (days < 0) {
                      status = '⚠️ लसीकरण ${-days} दिवस उशीर';
                      color = Colors.red;
                    } else if (days <= 7) {
                      status = '🔔 लसीकरण $days दिवसात ($dueStr)';
                      color = Colors.orange;
                    } else {
                      status = '✅ लसीकरण: $dueStr';
                      color = Colors.green;
                    }
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: Text(m['type'] == 'म्हैस' ? '🐃' : '🐄',
                          style: const TextStyle(fontSize: 32)),
                      title: Text('${m['name']}  (टॅग: ${m['tag']})',
                          style: const TextStyle(fontSize: 18)),
                      subtitle: Text(status,
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w600)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => d.reference.delete(),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}