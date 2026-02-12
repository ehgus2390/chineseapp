import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../state/app_state.dart';
import '../state/locale_state.dart';
import '../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<String> availableLanguages = <String>['ko', 'ja', 'en'];
  static const List<String> availableInterests = <String>[
    'Sport',
    'Movie',
    'Dance',
    'Music',
    'Singing',
    'Game',
    'Travel',
    'Cooking',
    'Fitness',
  ];

  final nameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final occupationCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  bool _seeded = false;
  bool _uploading = false;
  int _avatarVersion = 0;
  String _gender = 'male';
  final Set<String> _languages = <String>{};
  final Set<String> _interests = <String>{};
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    nameCtrl.dispose();
    ageCtrl.dispose();
    occupationCtrl.dispose();
    countryCtrl.dispose();
    bioCtrl.dispose();
    super.dispose();
  }

  void _seedFromProfile(AppState state) {
    if (_seeded) return;
    final me = state.meOrNull;
    if (me == null) return;
    _seeded = true;
    nameCtrl.text = me.name;
    ageCtrl.text = me.age == 0 ? '' : me.age.toString();
    occupationCtrl.text = me.occupation;
    countryCtrl.text = me.country;
    bioCtrl.text = me.bio;
    _gender = me.gender;
    _languages
      ..clear()
      ..addAll(me.languages);
    _interests
      ..clear()
      ..addAll(me.interests);
  }

  String _cacheBustedUrl(String url) {
    if (url.isEmpty) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=$_avatarVersion';
  }

  Future<void> _pickAvatar(AppState state) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    final bytes = await file.readAsBytes();
    try {
      await state.uploadAvatar(bytes);
      _avatarVersion += 1;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    if (!mounted) return;
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final localeState = context.watch<LocaleState>();
    _seedFromProfile(state);

    final me = state.meOrNull;
    if (me == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey.shade300,
                  child: (me.photoUrl == null || me.photoUrl!.isEmpty)
                      ? const Icon(Icons.person)
                      : ClipOval(
                          child: Image.network(
                            _cacheBustedUrl(me.photoUrl!),
                            key: ValueKey('${me.photoUrl}-$_avatarVersion'),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person),
                          ),
                        ),
                ),
                if (_uploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(36),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    me.name.isEmpty ? l.profileTitle : me.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('${l.country}: ${me.country}'),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.photo_camera),
              onPressed: _uploading ? null : () => _pickAvatar(state),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(l.appLanguage, style: Theme.of(context).textTheme.titleMedium),
        DropdownButton<Locale>(
          value:
              localeState.locale ??
              Locale(Localizations.localeOf(context).languageCode),
          onChanged: (value) async {
            await context.read<LocaleState>().setLocale(value);
          },
          items: const [
            DropdownMenuItem(value: Locale('ko'), child: Text('Korean')),
            DropdownMenuItem(value: Locale('ja'), child: Text('Japanese')),
            DropdownMenuItem(value: Locale('en'), child: Text('English')),
          ],
        ),
        const SizedBox(height: 24),
        Text(l.profileTitle, style: Theme.of(context).textTheme.titleMedium),
        TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: l.name),
        ),
        TextField(
          controller: ageCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.age),
        ),
        TextField(
          controller: occupationCtrl,
          decoration: InputDecoration(labelText: l.occupation),
        ),
        TextField(
          controller: countryCtrl,
          decoration: InputDecoration(labelText: l.country),
        ),
        const SizedBox(height: 12),
        Text(l.interests),
        Wrap(
          spacing: 8,
          children: availableInterests.map((String label) {
            final bool selected = _interests.contains(label);
            return FilterChip(
              label: Text(label),
              selected: selected,
              onSelected: (bool value) {
                setState(() {
                  if (value) {
                    _interests.add(label);
                  } else {
                    _interests.remove(label);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text(l.gender),
        DropdownButton<String>(
          value: _gender,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _gender = value);
          },
          items: [
            DropdownMenuItem(value: 'male', child: Text(l.male)),
            DropdownMenuItem(value: 'female', child: Text(l.female)),
          ],
        ),
        const SizedBox(height: 12),
        Text(l.yourLanguages),
        Wrap(
          spacing: 8,
          children: availableLanguages.map((String code) {
            final bool selected = _languages.contains(code);
            return FilterChip(
              label: Text(code.toUpperCase()),
              selected: selected,
              onSelected: (bool value) {
                setState(() {
                  if (value) {
                    _languages.add(code);
                  } else {
                    _languages.remove(code);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: bioCtrl,
          decoration: InputDecoration(labelText: l.bio),
          maxLines: 3,
        ),
        Text(l.preferences, style: Theme.of(context).textTheme.titleMedium),
        Text(l.prefTarget),
        Wrap(
          spacing: 8,
          children: availableLanguages.map((String code) {
            final bool selected = state.myPreferredLanguages.contains(code);
            return FilterChip(
              label: Text(code.toUpperCase()),
              selected: selected,
              onSelected: (bool value) async {
                await state.setPreferredLanguage(code, value);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            final int age = int.tryParse(ageCtrl.text.trim()) ?? 0;
            await state.saveProfile(
              name: nameCtrl.text.trim(),
              age: age,
              occupation: occupationCtrl.text.trim(),
              country: countryCtrl.text.trim(),
              interests: _interests.toList(),
              gender: _gender,
              languages: _languages.toList(),
              bio: bioCtrl.text.trim(),
              distanceKm: me.distanceKm,
              location: me.location,
            );
          },
          child: Text(l.save),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async {
            await state.signOut();
          },
          child: Text(l.signOut),
        ),
      ],
    );
  }
}
