import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/constants.dart';
import 'package:selfcheckoutapp/screens/profile.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';
import 'package:selfcheckoutapp/widgets/profile_avatar.dart';

class AppDrawer extends StatelessWidget {
  final FirebaseServices _firebaseServices = FirebaseServices();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: FutureBuilder<DocumentSnapshot>(
              future: _firebaseServices.getUserData(_firebaseServices.userId!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  return Text(
                    userData['name'] ?? 'User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return Text(
                  'Loading...',
                  style: TextStyle(color: Colors.white),
                );
              },
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                ListTile(
                  onTap: () {
                    showAboutDialog(
                        context: context,
                        applicationName: 'ScanGo',
                        applicationVersion: 'Version 1.0',
                        applicationLegalese:
                            'ScanGo is a Self-Checkout Mobile Application.\n\n'
                            'Scan->Add->Check->Pay->Go');
                  },
                  dense: true,
                  title: Text("About App", style: Constants.regularDarkText),
                  leading: Icon(
                    Icons.info,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                ListTile(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  dense: true,
                  title: Text("Close", style: Constants.regularDarkText),
                  leading: Icon(
                    Icons.close_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: CustomBtn(
              text: "Logout",
              onPressed: () {
                confirmationAlert(context);
                // setState(() {
                //   confirmationAlert(context);
                // });
              },
              outlineBtn: true,
            ),
          ),
        ],
      ),
    );
  }
}

confirmationAlert(BuildContext context) {
  return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
            title: Text("Logout?"),
            content: Text("Do you want to Logout?"),
            actions: [
              TextButton(
                child: Text(
                  "No",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text(
                  "Yes",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                },
              ),
            ],
          ));
}
