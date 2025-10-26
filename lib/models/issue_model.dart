enum IssueType { water, urban }

extension IssueTypeExtension on IssueType {
  String get typeDisplayName {
    switch (this) {
      case IssueType.water:
        return 'Water Issue';
      case IssueType.urban:
        return 'Urban Issue';
    }
  }
}

class Issue {
  final String issueId;
  final String userId;
  final IssueType type;
  final String description;
  final String? imageURL;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String status; // 'reported', 'verified', 'resolved'

  Issue({
    required this.issueId,
    required this.userId,
    required this.type,
    required this.description,
    this.imageURL,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.status = 'reported',
  });

  factory Issue.fromMap(Map<String, dynamic> map) {
    return Issue(
      issueId: map['issueId'] ?? '',
      userId: map['userId'] ?? '',
      type: IssueType.values.firstWhere(
        (e) => e.toString() == 'IssueType.${map['type']}',
        orElse: () => IssueType.water,
      ),
      description: map['description'] ?? '',
      imageURL: map['imageURL'],
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      status: map['status'] ?? 'reported',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'issueId': issueId,
      'userId': userId,
      'type': type.toString().split('.').last,
      'description': description,
      'imageURL': imageURL,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case IssueType.water:
        return 'Water Issue';
      case IssueType.urban:
        return 'Urban Issue';
    }
  }

  String get typeIcon {
    switch (type) {
      case IssueType.water:
        return '💧';
      case IssueType.urban:
        return '🏗️';
    }
  }
}

