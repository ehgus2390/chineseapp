import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../models/match.dart';

class MatchService {
  final _uuid = const Uuid();

  /// 매우 단순한 예시: 상대 언어에 'ko' 또는 'en'이 겹치면 점수 +, 국적이 다르면 +, bio 키워드 있으면 + …
  double score(Profile me, Profile other, List<String> preferredLanguages) {
    double s = 0;
    if (other.languages.any(preferredLanguages.contains)) s += 2;
    if (me.nationality != other.nationality) s += 1;
    if (other.bio.toLowerCase().contains('korea') || other.bio.toLowerCase().contains('travel')) s += 0.5;
    return s;
  }

  MatchPair createMatch(String meId, String partnerId) {
    return MatchPair(
      id: _uuid.v4(),
      meId: meId,
      partnerId: partnerId,
      createdAt: DateTime.now(),
    );
  }
}
