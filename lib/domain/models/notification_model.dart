class NotificationModel {
  final int id;
  final String packageName;
  final String? title;
  final String? content;
  final String? subText;
  final int timestamp;
  final String? category;
  final String? groupKey;
  final bool isGroupSummary;
  final String? messagingUser;
  final bool isRead;
  final bool isStarred;
  final String? tags; // comma-separated tags (Feature 3: Unique - Tagging)

  // --- Merged from base.apk (com.example.fluter) ---
  final bool isOtp;
  final String? extractedCode;
  final bool isPriorityFlagged;
  final String? imagePath; // New feature: path to a saved attached image, if any

  NotificationModel({
    required this.id,
    required this.packageName,
    this.title,
    this.content,
    this.subText,
    required this.timestamp,
    this.category,
    this.groupKey,
    required this.isGroupSummary,
    this.messagingUser,
    this.isRead = false,
    this.isStarred = false,
    this.tags,
    this.isOtp = false,
    this.extractedCode,
    this.isPriorityFlagged = false,
    this.imagePath,
  });

  /// Get tags as a list
  List<String> get tagList {
    if (tags == null || tags!.isEmpty) return [];
    return tags!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }

  factory NotificationModel.fromMap(Map<Object?, Object?> map) {
    return NotificationModel(
      id: map['id'] as int,
      packageName: map['packageName'] as String,
      title: map['title'] as String?,
      content: map['content'] as String?,
      subText: map['subText'] as String?,
      timestamp: map['timestamp'] as int,
      category: map['category'] as String?,
      groupKey: map['groupKey'] as String?,
      isGroupSummary: map['isGroupSummary'] == 1 || map['isGroupSummary'] == true,
      messagingUser: map['messagingUser'] as String?,
      isRead: map['isRead'] == 1 || map['isRead'] == true,
      isStarred: map['isStarred'] == 1 || map['isStarred'] == true,
      tags: map['tags'] as String?,
      isOtp: map['isOtp'] == 1 || map['isOtp'] == true,
      extractedCode: map['extractedCode'] as String?,
      isPriorityFlagged: map['isPriorityFlagged'] == 1 || map['isPriorityFlagged'] == true,
      imagePath: map['imagePath'] as String?,
    );
  }

  NotificationModel copyWith({
    int? id,
    String? packageName,
    String? title,
    String? content,
    String? subText,
    int? timestamp,
    String? category,
    String? groupKey,
    bool? isGroupSummary,
    String? messagingUser,
    bool? isRead,
    bool? isStarred,
    String? tags,
    bool? isOtp,
    String? extractedCode,
    bool? isPriorityFlagged,
    String? imagePath,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      title: title ?? this.title,
      content: content ?? this.content,
      subText: subText ?? this.subText,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      groupKey: groupKey ?? this.groupKey,
      isGroupSummary: isGroupSummary ?? this.isGroupSummary,
      messagingUser: messagingUser ?? this.messagingUser,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      tags: tags ?? this.tags,
      isOtp: isOtp ?? this.isOtp,
      extractedCode: extractedCode ?? this.extractedCode,
      isPriorityFlagged: isPriorityFlagged ?? this.isPriorityFlagged,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
