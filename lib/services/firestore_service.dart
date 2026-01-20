import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AppUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get user by ID
  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<bool> addFriend(String currentUserId, String friendId) async {
    try {
      // Add to current user's friends
      await _firestore.collection('users').doc(currentUserId).update({
        'friendIds': FieldValue.arrayUnion([friendId]),
      });

      // Add to friend's friends
      await _firestore.collection('users').doc(friendId).update({
        'friendIds': FieldValue.arrayUnion([currentUserId]),
      });

      return true;
    } catch (e) {
      print('Error adding friend: $e');
      return false;
    }
  }

  Stream<List<AppUser>> getFriends(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((doc) async {
      final data = doc.data();
      final friendIds = List<String>.from(data?['friendIds'] ?? []);

      if (friendIds.isEmpty) return <AppUser>[];

      final friends = <AppUser>[];
      for (final friendId in friendIds) {
        final friend = await getUser(friendId);
        if (friend != null) friends.add(friend);
      }
      return friends;
    });
  }

  Future<String?> createGroup({
    required String name,
    required String icon,
    required List<String> memberIds,
    required String createdBy,
  }) async {
    try {
      final docRef = await _firestore.collection('groups').add({
        'name': name,
        'icon': icon,
        'memberIds': memberIds,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'balances': {},
      });
      return docRef.id;
    } catch (e) {
      print('Error creating group: $e');
      return null;
    }
  }

  Stream<List<ExpenseGroup>> getGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .orderBy('lastActivity', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ExpenseGroup.fromFirestore(doc))
        .toList());
  }

  Future<ExpenseGroup?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists) {
        return ExpenseGroup.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting group: $e');
      return null;
    }
  }

  Future<String?> addExpense({
    required String groupId,
    required double amount,
    required String description,
    required String category,
    required String paidBy,
    required List<String> splitBetween,
    required SplitType splitType,
    required Map<String, double> splitDetails,
  }) async {
    try {
      final docRef = await _firestore.collection('expenses').add({
        'groupId': groupId,
        'amount': amount,
        'description': description,
        'category': category,
        'paidBy': paidBy,
        'splitBetween': splitBetween,
        'splitType': splitType.toString().split('.').last,
        'splitDetails': splitDetails,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _updateGroupBalances(groupId);

      await _firestore.collection('groups').doc(groupId).update({
        'lastActivity': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error adding expense: $e');
      return null;
    }
  }

  Stream<List<Expense>> getExpenses(String groupId) {
    return _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Expense.fromFirestore(doc))
        .toList());
  }

  // Delete expense
  Future<bool> deleteExpense(String expenseId, String groupId) async {
    try {
      await _firestore.collection('expenses').doc(expenseId).delete();
      await _updateGroupBalances(groupId);
      return true;
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }

  // ✅ DELETE GROUP - Add this method here!
  Future<bool> deleteGroup(String groupId) async {
    try {
      // First delete all expenses in this group
      final expensesSnapshot = await _firestore
          .collection('expenses')
          .where('groupId', isEqualTo: groupId)
          .get();

      for (final doc in expensesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Then delete the group
      await _firestore.collection('groups').doc(groupId).delete();
      return true;
    } catch (e) {
      print('Error deleting group: $e');
      return false;
    }
  }

  // Update group balances
  Future<void> _updateGroupBalances(String groupId) async {
    try {
      final expensesSnapshot = await _firestore
          .collection('expenses')
          .where('groupId', isEqualTo: groupId)
          .get();

      final expenses = expensesSnapshot.docs
          .map((doc) => Expense.fromFirestore(doc))
          .toList();

      final balances = <String, double>{};

      for (final expense in expenses) {
        balances[expense.paidBy] = (balances[expense.paidBy] ?? 0) + expense.amount;

        for (final entry in expense.splitDetails.entries) {
          balances[entry.key] = (balances[entry.key] ?? 0) - entry.value;
        }
      }

      await _firestore.collection('groups').doc(groupId).update({
        'balances': balances,
      });
    } catch (e) {
      print('Error updating balances: $e');
    }
  }

  // ========================================================================
  // SETTLEMENT CALCULATIONS
  // ========================================================================

  Future<List<Settlement>> calculateSettlements(String groupId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) return [];

      final balances = Map<String, double>.from(group.balances);
      final settlements = <Settlement>[];

      final creditors = <MapEntry<String, double>>[];
      final debtors = <MapEntry<String, double>>[];

      balances.forEach((userId, balance) {
        if (balance > 0.01) {
          creditors.add(MapEntry(userId, balance));
        } else if (balance < -0.01) {
          debtors.add(MapEntry(userId, balance));
        }
      });

      creditors.sort((a, b) => b.value.compareTo(a.value));
      debtors.sort((a, b) => a.value.compareTo(b.value));

      int i = 0, j = 0;
      while (i < creditors.length && j < debtors.length) {
        final creditor = creditors[i];
        final debtor = debtors[j];

        final amount = creditor.value < debtor.value.abs()
            ? creditor.value
            : debtor.value.abs();

        if (amount > 0.01) {
          settlements.add(Settlement(
            fromUserId: debtor.key,
            toUserId: creditor.key,
            amount: double.parse(amount.toStringAsFixed(2)),
          ));
        }

        creditors[i] = MapEntry(creditor.key, creditor.value - amount);
        debtors[j] = MapEntry(debtor.key, debtor.value + amount);

        if (creditors[i].value < 0.01) i++;
        if (debtors[j].value.abs() < 0.01) j++;
      }

      return settlements;
    } catch (e) {
      print('Error calculating settlements: $e');
      return [];
    }
  }
}