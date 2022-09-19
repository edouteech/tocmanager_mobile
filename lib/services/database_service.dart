import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // reference for our collections
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection("users");


  // saving the userdata
  Future savingUserData(String fullName, String email, String phone, String country) async {
    return await userCollection.doc(uid).set({
      "fullName": fullName,
      "email": email,
      "phone": phone,
      "country": country,
      "uid": uid,
    });
  }

  // getting user data
  Future gettingUserData(String email) async {
    QuerySnapshot snapshot =
        await userCollection.where("email", isEqualTo: email).get();
    return snapshot;
  }

  
}