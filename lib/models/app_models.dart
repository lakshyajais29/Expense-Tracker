import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String avatar;
  final String? photoURL;
  final bool profileComplete;
  final DateTime? createdAt;
  final List<String> friendIds;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.avatar,
    this.photoURL,
    this.profileComplete = false,
    this.createdAt,
    this.friendIds = const [],
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      avatar: data['avatar'] ?? '😎',
      photoURL: data['photoURL'],
      profileComplete: data['profileComplete'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      friendIds: List<String>.from(data['friendIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'avatar': avatar,
      'photoURL': photoURL,
      'profileComplete': profileComplete,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'friendIds': friendIds,
    };
  }
}

// ============================================================================
// GROUP MODEL
// ============================================================================
class ExpenseGroup {
  final String id;
  final String name;
  final String icon;
  final List<String> memberIds;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? lastActivity;
  final Map<String, double> balances;

  ExpenseGroup({
    required this.id,
    required this.name,
    required this.icon,
    required this.memberIds,
    required this.createdBy,
    required this.createdAt,
    this.lastActivity,
    this.balances = const {},
  });

  factory ExpenseGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseGroup(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '👥',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActivity: (data['lastActivity'] as Timestamp?)?.toDate(),
      balances: Map<String, double>.from(data['balances'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'memberIds': memberIds,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivity': lastActivity != null ? Timestamp.fromDate(lastActivity!) : null,
      'balances': balances,
    };
  }

  double getTotalExpenses() {
    return balances.values.fold(0, (sum, balance) => sum + balance.abs());
  }

  int getMemberCount() {
    return memberIds.length;
  }
}

// ============================================================================
// EXPENSE MODEL
// ============================================================================
enum SplitType {
  equal,
  percentage,
  exact,
  shares,
}

class Expense {
  final String id;
  final String groupId;
  final double amount;
  final String description;
  final String category;
  final String paidBy;
  final List<String> splitBetween;
  final SplitType splitType;
  final Map<String, double> splitDetails;
  final DateTime createdAt;
  final String? billImageUrl;

  Expense({
    required this.id,
    required this.groupId,
    required this.amount,
    required this.description,
    required this.category,
    required this.paidBy,
    required this.splitBetween,
    this.splitType = SplitType.equal,
    required this.splitDetails,
    required this.createdAt,
    this.billImageUrl,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      paidBy: data['paidBy'] ?? '',
      splitBetween: List<String>.from(data['splitBetween'] ?? []),
      splitType: SplitType.values.firstWhere(
            (e) => e.toString() == 'SplitType.${data['splitType']}',
        orElse: () => SplitType.equal,
      ),
      splitDetails: Map<String, double>.from(data['splitDetails'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      billImageUrl: data['billImageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'amount': amount,
      'description': description,
      'category': category,
      'paidBy': paidBy,
      'splitBetween': splitBetween,
      'splitType': splitType.toString().split('.').last,
      'splitDetails': splitDetails,
      'createdAt': Timestamp.fromDate(createdAt),
      'billImageUrl': billImageUrl,
    };
  }

  double getShareForUser(String userId) {
    return splitDetails[userId] ?? 0.0;
  }
}


class Settlement {
  final String fromUserId;
  final String toUserId;
  final double amount;

  Settlement({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });
}

// ============================================================================
// CATEGORY DATA
// ============================================================================
class ExpenseCategory {
  final String name;
  final String emoji;
  final String colorHex;

  ExpenseCategory({
    required this.name,
    required this.emoji,
    required this.colorHex,
  });

  static List<ExpenseCategory> defaultCategories = [
    ExpenseCategory(name: 'Food', emoji: '🍕', colorHex: '#EF4444'),
    ExpenseCategory(name: 'Transport', emoji: '🚗', colorHex: '#F59E0B'),
    ExpenseCategory(name: 'Shopping', emoji: '🛍️', colorHex: '#EC4899'),
    ExpenseCategory(name: 'Entertainment', emoji: '🎬', colorHex: '#8B5CF6'),
    ExpenseCategory(name: 'Bills', emoji: '📱', colorHex: '#3B82F6'),
    ExpenseCategory(name: 'Health', emoji: '💊', colorHex: '#10B981'),
    ExpenseCategory(name: 'Education', emoji: '📚', colorHex: '#6366F1'),
    ExpenseCategory(name: 'Other', emoji: '💰', colorHex: '#6B7280'),
  ];
}

class AvatarData {
  static List<String> availableAvatars = [
    '😎', '🤓', '🥳', '🤪', '🤑', '😈', '🦸', '🧙',
    '🤠', '🥷', '👨‍💻', '👨‍🎓', '👨‍🎤', '👨‍🚀', '🧑‍🎨', '🧑‍🍳',
    '💪', '🔥', '⚡', '🎯', '🏆', '⭐', '💎', '👑',
  ];
}