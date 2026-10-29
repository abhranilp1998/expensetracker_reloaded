import 'package:flutter/material.dart';

import 'package:expensetracker_reloaded/services/debug_unlock_service.dart';
import 'package:expensetracker_reloaded/widgets/debug_pin_dialog.dart';

/// Settings card: set, change or remove the Debug PIN (bug #14/#20).
/// Change and remove first ask for the current PIN or biometrics.
class DebugPinSection extends StatefulWidget {
  const DebugPinSection({super.key});

  @override
  State<DebugPinSection> createState() => _DebugPinSectionState();
}

class _DebugPinSectionState extends State<DebugPinSection> {
  bool? _hasPin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final has = await DebugUnlockService.hasPin();
    if (mounted) setState(() => _hasPin = has);
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<bool> _verify() =>
      showDebugPinDialog(context, PinDialogMode.verifyCurrent);

  Future<void> _set() async {
    if (await showDebugPinDialog(context, PinDialogMode.setup)) {
      _toast('Debug PIN set');
    }
    await _load();
  }

  Future<void> _change() async {
    if (!await _verify() || !mounted) return;
    if (await showDebugPinDialog(context, PinDialogMode.setup)) {
      _toast('Debug PIN changed');
    }
    await _load();
  }

  Future<void> _remove() async {
    if (!await _verify() || !mounted) return;
    await DebugUnlockService.removePin();
    _toast('Debug PIN removed');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final has = _hasPin;
    return Card(
      key: const Key('debugPinCard'),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.pin_outlined, color: cs.primary),
            title: const Text('Debug PIN'),
            subtitle: Text(
              has == null
                  ? '…'
                  : has
                  ? 'Set. Protects the Debug area (fingerprint also works).'
                  : 'Not set. You will be asked to set one when opening Debug.',
            ),
          ),
          if (has != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                children: has
                    ? [
                        OutlinedButton(
                          key: const Key('changePin'),
                          onPressed: _change,
                          child: const Text('Change PIN'),
                        ),
                        TextButton(
                          key: const Key('removePin'),
                          onPressed: _remove,
                          child: const Text('Remove PIN'),
                        ),
                      ]
                    : [
                        FilledButton(
                          key: const Key('setPin'),
                          onPressed: _set,
                          child: const Text('Set PIN'),
                        ),
                      ],
              ),
            ),
        ],
      ),
    );
  }
}
