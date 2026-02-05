import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kkiri/l10n/app_localizations.dart';
import '../state/app_state.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  final TextEditingController _uidCtrl = TextEditingController();
  final TextEditingController _banReasonCtrl = TextEditingController();
  final TextEditingController _banUntilCtrl = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  String? _error;

  int _level = 0;
  int _totalReports = 0;
  bool _protectionEligible = true;
  bool _hardSevere = false;
  bool _hardSexual = false;
  bool _hardViolence = false;
  bool _hardSpam = false;

  bool _protectionActive = false;
  DateTime? _protectionExpiresAt;
  bool _banActive = false;
  DateTime? _banUntil;

  @override
  void dispose() {
    _uidCtrl.dispose();
    _banReasonCtrl.dispose();
    _banUntilCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser(AppLocalizations l) async {
    final uid = _uidCtrl.text.trim();
    if (uid.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final moderationSnap = await FirebaseFirestore.instance
          .collection('user_moderation')
          .doc(uid)
          .get();
      final entSnap = await FirebaseFirestore.instance
          .collection('user_entitlements')
          .doc(uid)
          .get();

      final moderation = moderationSnap.data() ?? <String, dynamic>{};
      final ent = entSnap.data() ?? <String, dynamic>{};
      final hardFlags = moderation['hardFlags'] as Map<String, dynamic>? ?? {};
      final protection = ent['protection'] as Map<String, dynamic>? ?? {};
      final ban = ent['protectionBan'] as Map<String, dynamic>? ?? {};

      final banUntil = ban['until'];
      final protectionExpires = protection['expiresAt'];

      setState(() {
        _level = (moderation['level'] ?? 0) as int;
        _totalReports = (moderation['totalReports'] ?? 0) as int;
        _protectionEligible = moderation['protectionEligible'] != false;
        _hardSevere = hardFlags['severe'] == true;
        _hardSexual = hardFlags['sexual'] == true;
        _hardViolence = hardFlags['violence'] == true;
        _hardSpam = hardFlags['spam'] == true;

        _protectionActive = protection['active'] == true;
        _protectionExpiresAt =
            protectionExpires is Timestamp ? protectionExpires.toDate() : null;
        _banActive = ban['active'] == true;
        _banReasonCtrl.text = (ban['reason'] ?? '').toString();
        _banUntil =
            banUntil is Timestamp ? banUntil.toDate() : DateTime.tryParse(banUntil?.toString() ?? '');
        _banUntilCtrl.text = _formatDate(_banUntil);
      });
    } catch (_) {
      setState(() => _error = l.adminLoadFailed);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save(AppLocalizations l) async {
    final uid = _uidCtrl.text.trim();
    if (uid.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final until = _parseDate(_banUntilCtrl.text.trim());
      await context.read<AppState>().adminUpdateModeration(
            uid: uid,
            protectionEligible: _protectionEligible,
            hardFlags: <String, bool>{
              'severe': _hardSevere,
              'sexual': _hardSexual,
              'violence': _hardViolence,
              'spam': _hardSpam,
            },
            banActive: _banActive,
            banReason: _banReasonCtrl.text.trim(),
            banUntil: until,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.adminSaved)),
      );
    } catch (_) {
      setState(() => _error = l.adminLoadFailed);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime? _parseDate(String input) {
    if (input.isEmpty) return null;
    return DateTime.tryParse(input);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.adminTitle)),
      body: state.isAdmin
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _uidCtrl,
                  decoration: InputDecoration(labelText: l.adminUidLabel),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : () => _loadUser(l),
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.adminLoadUser),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                _InfoRow(label: l.adminModerationLevel, value: '$_level'),
                _InfoRow(label: l.adminTotalReports, value: '$_totalReports'),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _protectionEligible,
                  onChanged: (v) => setState(() => _protectionEligible = v),
                  title: Text(l.adminProtectionEligible),
                ),
                const SizedBox(height: 8),
                Text(l.adminHardFlags),
                CheckboxListTile(
                  value: _hardSevere,
                  onChanged: (v) => setState(() => _hardSevere = v ?? false),
                  title: Text(l.adminHardFlagSevere),
                ),
                CheckboxListTile(
                  value: _hardSexual,
                  onChanged: (v) => setState(() => _hardSexual = v ?? false),
                  title: Text(l.adminHardFlagSexual),
                ),
                CheckboxListTile(
                  value: _hardViolence,
                  onChanged: (v) => setState(() => _hardViolence = v ?? false),
                  title: Text(l.adminHardFlagViolence),
                ),
                CheckboxListTile(
                  value: _hardSpam,
                  onChanged: (v) => setState(() => _hardSpam = v ?? false),
                  title: Text(l.adminHardFlagSpam),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: l.adminProtectionActive,
                  value: _protectionActive ? 'ON' : 'OFF',
                ),
                _InfoRow(
                  label: l.adminProtectionExpiresAt,
                  value: _formatDate(_protectionExpiresAt),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _banActive,
                  onChanged: (v) => setState(() => _banActive = v),
                  title: Text(l.adminProtectionBanActive),
                ),
                TextField(
                  controller: _banUntilCtrl,
                  decoration: InputDecoration(
                    labelText: l.adminProtectionBanUntil,
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _banReasonCtrl,
                  decoration: InputDecoration(labelText: l.adminProtectionBanReason),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : () => _save(l),
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.adminSave),
                  ),
                ),
              ],
            )
          : Center(child: Text(l.adminNotAuthorized)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
}
