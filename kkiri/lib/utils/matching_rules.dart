/// Matching logic for cross-gender, cross-country visibility.
///
/// Only Japanese women (JP, female) and Korean men (KR, male) should see each other.
/// Same genders or other country/gender mixes are hidden.
bool isTargetMatch(
  String? myGender,
  String? myCountry,
  String? otherGender,
  String? otherCountry,
) {
  const jp = 'JP';
  const kr = 'KR';

  final isJapaneseWoman = myGender == 'female' && myCountry == jp;
  final isKoreanMan = myGender == 'male' && myCountry == kr;

  if (isJapaneseWoman) {
    return otherGender == 'male' && otherCountry == kr;
  }

  if (isKoreanMan) {
    return otherGender == 'female' && otherCountry == jp;
  }

  return false;
}
