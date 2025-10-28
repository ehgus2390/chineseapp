import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadChatImage({
    required String chatId,
    required String senderUid,
    required File file,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('chats/$chatId/$senderUid-$ts.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  Future<String> uploadProfileImage({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref('profiles/$uid.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }
}
