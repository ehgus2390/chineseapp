import '../models/profile.dart';

class MatchService {
  double score(Profile me, Profile other, List<String> preferredLanguages) {
    double s = 0;
    if (other.languages.any(preferredLanguages.contains)) s += 2;
    if (me.country != other.country) s += 1;
    if (other.bio.toLowerCase().contains('korea') ||
        other.bio.toLowerCase().contains('travel')) {
      s += 0.5;
    }
    return s;
  }
}
