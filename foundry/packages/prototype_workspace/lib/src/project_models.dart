class PrototypeRevision {
  const PrototypeRevision({
    required this.id,
    required this.number,
    required this.createdAt,
    required this.brief,
    required this.rawContract,
    required this.screenId,
    required this.screenTitle,
  });

  factory PrototypeRevision.fromJson(Map<String, Object?> json) {
    return PrototypeRevision(
      id: json['id']! as String,
      number: json['number']! as int,
      createdAt: DateTime.parse(json['createdAt']! as String),
      brief: json['brief']! as String,
      rawContract: json['rawContract']! as String,
      screenId: json['screenId']! as String,
      screenTitle: json['screenTitle']! as String,
    );
  }

  final String id;
  final int number;
  final DateTime createdAt;
  final String brief;
  final String rawContract;
  final String screenId;
  final String screenTitle;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'number': number,
        'createdAt': createdAt.toIso8601String(),
        'brief': brief,
        'rawContract': rawContract,
        'screenId': screenId,
        'screenTitle': screenTitle,
      };
}

class PrototypeReviewComment {
  const PrototypeReviewComment({
    required this.id,
    required this.revisionId,
    required this.text,
    required this.createdAt,
  });

  factory PrototypeReviewComment.fromJson(Map<String, Object?> json) {
    return PrototypeReviewComment(
      id: json['id']! as String,
      revisionId: json['revisionId']! as String,
      text: json['text']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
    );
  }

  final String id;
  final String revisionId;
  final String text;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'revisionId': revisionId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };
}

class PrototypeProject {
  PrototypeProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    List<PrototypeRevision> revisions = const <PrototypeRevision>[],
    List<PrototypeReviewComment> comments = const <PrototypeReviewComment>[],
  })  : revisions = List<PrototypeRevision>.unmodifiable(revisions),
        comments = List<PrototypeReviewComment>.unmodifiable(comments);

  factory PrototypeProject.fromJson(Map<String, Object?> json) {
    final List<Object?> revisions = json['revisions']! as List<Object?>;
    final List<Object?> comments = json['comments']! as List<Object?>;
    return PrototypeProject(
      id: json['id']! as String,
      name: json['name']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
      revisions: revisions
          .map(
            (Object? value) => PrototypeRevision.fromJson(
              Map<String, Object?>.from(value! as Map<Object?, Object?>),
            ),
          )
          .toList(),
      comments: comments
          .map(
            (Object? value) => PrototypeReviewComment.fromJson(
              Map<String, Object?>.from(value! as Map<Object?, Object?>),
            ),
          )
          .toList(),
    );
  }

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PrototypeRevision> revisions;
  final List<PrototypeReviewComment> comments;

  PrototypeProject copyWith({
    String? name,
    DateTime? updatedAt,
    List<PrototypeRevision>? revisions,
    List<PrototypeReviewComment>? comments,
  }) {
    return PrototypeProject(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revisions: revisions ?? this.revisions,
      comments: comments ?? this.comments,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'revisions': revisions
            .map((PrototypeRevision revision) => revision.toJson())
            .toList(),
        'comments': comments
            .map((PrototypeReviewComment comment) => comment.toJson())
            .toList(),
      };
}
