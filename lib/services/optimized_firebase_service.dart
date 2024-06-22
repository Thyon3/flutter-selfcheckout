import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';

class OptimizedFirebaseService extends FirebaseServices {
  static const int _pageSize = 20;
  
  Future<QuerySnapshot> getProductsPaginated({
    DocumentSnapshot? lastDocument,
    String? category,
  }) async {
    Query query = productsRef.orderBy('name').limit(_pageSize);
    
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    
    return await query.get();
  }

  Future<QuerySnapshot> getUserCartPaginated({
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = usersCartRef
        .doc(getUserId())
        .collection('Cart')
        .orderBy('timestamp', descending: true)
        .limit(_pageSize);
    
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    
    return await query.get();
  }

  Future<QuerySnapshot> getUserHistoryPaginated({
    DocumentSnapshot? lastDocument,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = usersCartHistoryRef
        .doc(getUserId())
        .collection('Cart')
        .orderBy('time', descending: true)
        .limit(_pageSize);
    
    if (startDate != null) {
      query = query.where('time', isGreaterThanOrEqualTo: startDate);
    }
    
    if (endDate != null) {
      query = query.where('time', isLessThanOrEqualTo: endDate);
    }
    
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    
    return await query.get();
  }

  Stream<QuerySnapshot> getRealtimeProducts({
    String? category,
    int limit = 50,
  }) {
    Query query = productsRef.orderBy('name').limit(limit);
    
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    
    return query.snapshots();
  }
}
