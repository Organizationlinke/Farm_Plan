import 'package:farmplanning/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
   const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  await Supabase.initialize(
    //      url: supabaseUrl, // قراءة URL
    // anonKey: supabaseAnonKey, // قراءة المفتاح
    url: 'https://rfnklwurcdgbfjsatato.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmbmtsd3VyY2RnYmZqc2F0YXRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk4MTEzMDEsImV4cCI6MjA1NTM4NzMwMX0.f8Ga6bTaiaB3-phm1j4OCnuE5im8rCcBywJXVunCD8M',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(),
    );
  }
}



