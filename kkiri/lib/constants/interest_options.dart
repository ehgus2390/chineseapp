import 'package:flutter/material.dart';

class InterestOption {
  const InterestOption({required this.id, required this.icon});

  final String id;
  final IconData icon;
}

const List<InterestOption> kInterestOptions = [
  InterestOption(id: 'coffee', icon: Icons.coffee),
  InterestOption(id: 'travel', icon: Icons.flight_takeoff),
  InterestOption(id: 'hiking', icon: Icons.landscape),
  InterestOption(id: 'music', icon: Icons.music_note),
  InterestOption(id: 'gaming', icon: Icons.sports_esports),
  InterestOption(id: 'art', icon: Icons.brush),
  InterestOption(id: 'foodie', icon: Icons.ramen_dining),
  InterestOption(id: 'language', icon: Icons.translate),
  InterestOption(id: 'kdrama', icon: Icons.live_tv),
  InterestOption(id: 'fitness', icon: Icons.self_improvement),
];

final Set<String> kInterestOptionIds = {
  for (final option in kInterestOptions) option.id,
};
