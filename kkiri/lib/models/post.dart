import 'comment.dart';

class Post {
  Post({
    required this.id,
    required this.authorId,
    required this.content,
    required this.createdAt,
    Set<String>? likedBy,
    List<Comment>? comments,
  })  : likedBy = likedBy ?? <String>{},
        comments = comments ?? <Comment>[];

  final String id;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final Set<String> likedBy;
  final List<Comment> comments;

  Post copyWith({
    String? id,
    String? authorId,
    String? content,
    DateTime? createdAt,
    Set<String>? likedBy,
    List<Comment>? comments,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likedBy: likedBy ?? Set<String>.from(this.likedBy),
      comments: comments ?? List<Comment>.from(this.comments),
    );
  }
}
