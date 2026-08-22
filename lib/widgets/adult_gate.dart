import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Blocks child-inaccessible actions behind a short adult check.
///
/// Google Play's Families policy requires an adult gate in front of the
/// parents' area, purchases, and destructive actions. The challenge is a
/// two-digit by one-digit multiplication: trivial for an adult with a
/// moment's thought, but beyond the mental arithmetic of the 6-12 year olds
/// this app targets — and, unlike a "tap and hold" gate, it cannot be
/// brute-forced by tapping.
class AdultGate {
  const AdultGate._();

  /// Shows the gate. Resolves true only when the answer is correct.
  ///
  /// [reason] is shown to the parent so they know what they are approving.
  static Future<bool> show(
    BuildContext context, {
    required String reason,
  }) async {
    final passed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _AdultGateDialog(reason: reason),
    );
    return passed ?? false;
  }
}

class _AdultGateDialog extends StatefulWidget {
  final String reason;
  const _AdultGateDialog({required this.reason});

  @override
  State<_AdultGateDialog> createState() => _AdultGateDialogState();
}

class _AdultGateDialogState extends State<_AdultGateDialog> {
  late int _a;
  late int _b;
  final TextEditingController _answer = TextEditingController();
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _newChallenge();
  }

  void _newChallenge() {
    final rnd = math.Random();
    _a = 12 + rnd.nextInt(88); // 12..99
    _b = 3 + rnd.nextInt(7); // 3..9
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_answer.text.trim());
    if (value == _a * _b) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _wrong = true;
      _answer.clear();
      _newChallenge();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Semantics(
        header: true,
        child: Row(
          children: [
            const Text('🔒', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(child: Text('Khusus Orang Tua', style: AppText.heading(22))),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.reason, style: AppText.body(16)),
          const SizedBox(height: 16),
          Text('Berapa hasil dari:', style: AppText.body(15)),
          const SizedBox(height: 6),
          Semantics(
            label: 'Soal verifikasi: $_a dikali $_b',
            excludeSemantics: true,
            child: Text('$_a × $_b = ?', style: AppText.heading(32)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _answer,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppText.heading(24),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Jawaban',
              errorText: _wrong ? 'Jawaban salah, coba soal baru.' : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Batal', style: AppText.body(17, color: Colors.grey)),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text('Lanjut', style: AppText.body(17, color: Colors.white)),
        ),
      ],
    );
  }
}
