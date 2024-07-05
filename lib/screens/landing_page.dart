import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/screens/home.dart';
import 'package:selfcheckoutapp/screens/login.dart';
import 'package:selfcheckoutapp/screens/loading.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';

class LandingPage extends StatelessWidget {
  final FirebaseServices _firebaseServices = FirebaseServices();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _firebaseServices._auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Loading(message: 'Initializing app...');
        }
        
        if (snapshot.hasData) {
          // User is logged in
          return HomePage();
        } else {
          // User is not logged in
          return LoginPage();
                body: Center(
                  child: Text("Error: ${streamSnapshot.error}"),
                ),
              );
            }

            //CONNECTION STATE ACTIVE - DO THE LOGIN
            if(streamSnapshot.connectionState == ConnectionState.active){

              //GET THE USER
              User _user = streamSnapshot.data;

              //IF THE USER IS NULL - NOT LOGGING IN
              if(_user == null){

                //USER NOT LOGGED IN - HEAD TO LOGIN PAGE
                return LoginPage();
              }else{

                //USER IS LOGGED IN - HEAD TO HOME PAGE
                return HomePage();
              }
            }

            //CHECKING THE AUTH STATE - LOADING
            return Scaffold(
              body: Center(
                child: Loading(),
              ),
            );
          },
          );
        }

        //CONNECTING TO FIREBASE - LOADING
        return Scaffold(
          body: Center(
            child: Text("Initialization App..."),
          ),
        );
      },
    );
  }
}
