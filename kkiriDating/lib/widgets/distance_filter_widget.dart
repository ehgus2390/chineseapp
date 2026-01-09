import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

class DistanceFilterWidget extends StatefulWidget {
  const DistanceFilterWidget({super.key});

  @override
  State<DistanceFilterWidget> createState() => _DistanceFilterWidgetState();
}

class _DistanceFilterWidgetState extends State<DistanceFilterWidget> {
  bool _seeded = false;
  bool _updatingLocation = false;
  double _distanceKm = 30;

  void _seedFromProfile(AppState state) {
    if (_seeded) return;
    final me = state.meOrNull;
    if (me == null) return;
    _seeded = true;
    _distanceKm = me.distanceKm;
  }

  Future<void> _useCurrentLocation(AppState state) async {
    final l = AppLocalizations.of(context);
    final hasService = await Geolocator.isLocationServiceEnabled();
    if (!hasService) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.locationServiceOff)));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.locationPermissionDenied)));
      return;
    }

    setState(() => _updatingLocation = true);
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final location = GeoPoint(position.latitude, position.longitude);
    await state.updateMatchPreferences(
      distanceKm: _distanceKm,
      location: location,
    );

    if (!mounted) return;
    setState(() => _updatingLocation = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.locationUpdated)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations.of(context);
    _seedFromProfile(state);
    final me = state.meOrNull;
    final location = me?.location;
    final lat = location?.latitude;
    final lng = location?.longitude;
    final distanceEnabled = state.distanceFilterEnabled;
    final distanceLabel =
        distanceEnabled ? '${_distanceKm.toStringAsFixed(0)} km' : '거리 제한 없음';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E6EA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.distance,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Switch(
                value: distanceEnabled,
                onChanged: (value) => state.setDistanceFilterEnabled(value),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(distanceLabel),
          Slider(
            min: 1,
            max: 200,
            value: _distanceKm.clamp(1, 200),
            label: '${_distanceKm.toStringAsFixed(0)} km',
            onChanged: distanceEnabled
                ? (value) => setState(() => _distanceKm = value)
                : null,
            onChangeEnd: (_) async {
              if (!distanceEnabled) return;
              await state.updateMatchPreferences(
                distanceKm: _distanceKm,
                location: location,
              );
            },
          ),
          const SizedBox(height: 8),
          Text(l.location, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ValueBox(
                  label: l.latitude,
                  value: lat == null ? '-' : lat.toStringAsFixed(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ValueBox(
                  label: l.longitude,
                  value: lng == null ? '-' : lng.toStringAsFixed(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _updatingLocation ? null : () => _useCurrentLocation(state),
              child: _updatingLocation
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.useCurrentLocation),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueBox extends StatelessWidget {
  final String label;
  final String value;

  const _ValueBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
