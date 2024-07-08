import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:selfcheckoutapp/constants.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';

class BillHistoryPage extends StatefulWidget {
  @override
  _BillHistoryPageState createState() => _BillHistoryPageState();
}

class _BillHistoryPageState extends State<BillHistoryPage> {
  final FirebaseServices _firebaseServices = FirebaseServices();

  Future<void> _deleteHistory(String documentId) async {
    await _firebaseServices.usersCartHistoryRef.doc(documentId).delete();
  }

  void _showDeleteConfirmation(String documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete History'),
        content: Text('Are you sure you want to delete this purchase history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteHistory(documentId);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      appBar: AppBar(
        title: Text(
          "Cart History",
          style: Constants.boldHeadingAppBar,
        ),
        backgroundColor: Color(0xff1faa00),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseServices.usersCartHistoryRef
            .doc(_firebaseServices.userId)
            .collection('purchases')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp?;
              final date = timestamp?.toDate() ?? DateTime.now();
              
              return Card(
                margin: EdgeInsets.only(bottom: 16.0),
                elevation: 4.0,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Purchase #${index + 1}',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff1faa00),
                            ),
                          ),
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'delete') {
                                _showDeleteConfirmation(doc.id);
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Date: ${date.toString().substring(0, 16)}',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Total: LKR ${data['total']?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (data['items'] != null) ...[
                        SizedBox(height: 12.0),
                        Text(
                          'Items:',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4.0),
                        ...List.generate(
                          (data['items'] as List).length,
                          (index) => Text(
                            '• ${(data['items'] as List)[index]['name']} - LKR ${(data['items'] as List)[index]['price']?.toStringAsFixed(2) ?? '0.00'}',
                            style: TextStyle(fontSize: 12.0),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80.0,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20.0),
          Text(
            'No purchase history',
            style: TextStyle(
              fontSize: 20.0,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10.0),
          Text(
            'Your shopping cart history will appear here',
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
