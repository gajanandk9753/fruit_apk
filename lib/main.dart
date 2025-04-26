import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize( //sps
    url: 'https://ofhyvxjbbqjgotsqzscg.supabase.co', // Replace with your URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9maHl2eGpiYnFqZ290c3F6c2NnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM5MjQ1NTcsImV4cCI6MjA1OTUwMDU1N30.zOjlMaAlRi2EwjbUMCZ9OjcLCxHmILtInlEwnMfU2OQ', // Replace with your key
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supabase Image Storage',
      home: HomeScreen(),
    );
  }
}
