import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDNiB6ASra4hLE5KMawTOZOpqrxgHGQC6g",
        authDomain: "kost-app-42889.firebaseapp.com",
        projectId: "kost-app-42889",
        storageBucket: "kost-app-42889.firebasestorage.app",
        messagingSenderId: "939968600167",
        appId: "1:939968600167:web:319ce168f8d288886c9cc2",
        measurementId: "G-1Z9HQLDBR5",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Kost',
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
