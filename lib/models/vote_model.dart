class Vote {
  final int id;
  final String title;
  final String description;
  final int channelId;
  final String createdBy;
  final String voteType;
  final bool isActive;
  final bool isAnonymous;
  final DateTime? endDate;
  final List<VoteOption> options;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool hasVoted;
  final int totalVotes;

  Vote({
    required this.id,
    required this.title,
    required this.description,
    required this.channelId,
    required this.createdBy,
    required this.voteType,
    required this.isActive,
    required this.isAnonymous,
    this.endDate,
    required this.options,
    required this.createdAt,
    this.updatedAt,
    required this.hasVoted,
    required this.totalVotes,
  });

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      channelId: json['channelId'],
      createdBy: json['createdBy'],
      voteType: json['voteType'],
      isActive: json['isActive'] ?? true,
      isAnonymous: json['isAnonymous'] ?? false,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      options: (json['options'] as List)
          .map((option) => VoteOption.fromJson(option))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      hasVoted: json['hasVoted'] ?? false,
      totalVotes: json['totalVotes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'channelId': channelId,
      'createdBy': createdBy,
      'voteType': voteType,
      'isActive': isActive,
      'isAnonymous': isAnonymous,
      'endDate': endDate?.toIso8601String(),
      'options': options.map((option) => option.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'hasVoted': hasVoted,
      'totalVotes': totalVotes,
    };
  }
}

class VoteOption {
  final int id;
  final String text;
  final int voteCount;
  final double percentage;

  VoteOption({
    required this.id,
    required this.text,
    required this.voteCount,
    required this.percentage,
  });

  factory VoteOption.fromJson(Map<String, dynamic> json) {
    return VoteOption(
      id: json['id'],
      text: json['text'],
      voteCount: json['voteCount'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'voteCount': voteCount,
      'percentage': percentage,
    };
  }
}