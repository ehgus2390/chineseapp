import 'app_localizations.dart';

String notificationLabel(AppLocalizations l, String key) {
  switch (key) {
    case 'notificationMessages':
      return l.notificationMessages;
    case 'notificationFriendRequests':
      return l.notificationFriendRequests;
    case 'notificationCommunityUpdates':
      return l.notificationCommunityUpdates;
    default:
      return key;
  }
}
