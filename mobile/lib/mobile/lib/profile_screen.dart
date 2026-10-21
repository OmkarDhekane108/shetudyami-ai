import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _village = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _village.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': _name.text.trim(),
      'village': _village.text.trim(),
      'phone': user.phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('तुमची माहिती')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _name,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                  labelText: 'नाव', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _village,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                  labelText: 'गाव', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('सेव्ह करा', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}