import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:expensetracker_reloaded/services/debug_unlock_service.dart';

/// What the PIN dialog is for.
enum PinDialogMode {
  /// Open the Debug area (PIN or biometric).
  unlock,

  /// Choose a new PIN: enter + confirm.
  setup,

  /// Prove you own the current PIN before change/remove (PIN or biometric).
  verifyCurrent,
}

/// Shows the PIN dialog. Returns true on success. Tapping outside never
/// closes it, so a half-typed PIN is not lost; use Cancel.
Future<bool> showDebugPinDialog(
  BuildContext context,
  PinDialogMode mode,
) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DebugPinDialog(mode: mode),
  );
  return ok == true;
}

/// Opens Debug: sets a PIN first if none exists, else asks for it.
Future<bool> unlockDebug(BuildContext context) async {
  if (DebugUnlockService.sessionUnlocked) return true;
  final has = await DebugUnlockService.hasPin();
  if (!context.mounted) return false;
  final ok = await showDebugPinDialog(
    context,
    has ? PinDialogMode.unlock : PinDialogMode.setup,
  );
  if (ok) DebugUnlockService.sessionUnlocked = true;
  return ok;
}

class DebugPinDialog extends StatefulWidget {
  const DebugPinDialog({super.key, required this.mode});
  final PinDialogMode mode;

  @override
  State<DebugPinDialog> createState() => _DebugPinDialogState();
}

class _DebugPinDialogState extends State<DebugPinDialog> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;
  Duration _locked = Duration.zero;
  Timer? _tick;

  bool get _isSetup => widget.mode == PinDialogMode.setup;

  @override
  void initState() {
    super.initState();
    if (!_isSetup) _refreshLock();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Reads the lockout and counts it down once a second.
  Future<void> _refreshLock() async {
    final left = await DebugUnlockService.lockRemaining();
    if (!mounted) return;
    setState(() => _locked = left);
    _tick?.cancel();
    if (left > Duration.zero) {
      _tick = Timer(const Duration(seconds: 1), _refreshLock);
    }
  }

  String _fmt(Duration d) {
    final s = d.inSeconds + 1;
    return s >= 60
        ? '${s ~/ 60}m ${(s % 60).toString().padLeft(2, '0')}s'
        : '${s}s';
  }

  Future<void> _bio() async {
    setState(() => _busy = true);
    final ok = await DebugUnlockService.verifyBiometric();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Biometric failed. Try your PIN.');
    }
  }

  Future<void> _submit() async {
    final pin = _pin.text;
    final err = DebugUnlockService.validatePin(pin);
    if (err != null) return setState(() => _error = err);

    if (_isSetup) {
      if (_confirm.text != pin) {
        return setState(() => _error = 'PINs do not match');
      }
      setState(() => _busy = true);
      await DebugUnlockService.setPin(pin);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    setState(() => _busy = true);
    final result = await DebugUnlockService.attemptPin(pin);
    if (!mounted) return;
    _busy = false;
    switch (result) {
      case PinResult.ok:
        Navigator.of(context).pop(true);
      case PinResult.wrong:
        final left = await DebugUnlockService.attemptsLeft();
        if (!mounted) return;
        _pin.clear();
        setState(() => _error = 'Wrong PIN. $left tries left.');
      case PinResult.lockedOut:
        _pin.clear();
        setState(() => _error = null);
        await _refreshLock();
    }
  }

  Widget _field(TextEditingController c, String label, Key key) => TextField(
    key: key,
    controller: c,
    obscureText: true,
    enabled: _locked == Duration.zero,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(6),
    ],
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    onChanged: (_) {
      if (_error != null) setState(() => _error = null);
    },
    onSubmitted: (_) => _submit(),
  );

  @override
  Widget build(BuildContext context) {
    final locked = _locked > Duration.zero;
    final title = switch (widget.mode) {
      PinDialogMode.setup => 'Set Debug PIN',
      PinDialogMode.unlock => 'Unlock Debug',
      PinDialogMode.verifyCurrent => 'Confirm current PIN',
    };
    final errColor = Theme.of(context).colorScheme.error;
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isSetup
                ? 'Choose a 4-6 digit PIN. Fingerprint also works later.'
                : 'Enter your Debug PIN or use biometrics.',
          ),
          const SizedBox(height: 16),
          _field(_pin, _isSetup ? 'New PIN' : 'PIN', const Key('pinField')),
          if (_isSetup) ...[
            const SizedBox(height: 12),
            _field(_confirm, 'Confirm PIN', const Key('pinConfirm')),
          ],
          if (locked) ...[
            const SizedBox(height: 8),
            Text(
              'Too many wrong tries. Try again in ${_fmt(_locked)}.',
              style: TextStyle(color: errColor),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: errColor)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        if (!_isSetup)
          TextButton(
            onPressed: _busy ? null : _bio,
            child: const Text('Biometric'),
          ),
        FilledButton(
          onPressed: _busy || locked ? null : _submit,
          child: Text(_isSetup ? 'Set PIN' : 'OK'),
        ),
      ],
    );
  }
}
