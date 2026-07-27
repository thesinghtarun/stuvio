import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/screens/custom_bottom_navigation.dart';
import 'package:studyvault/screens/tabs/search_tab.dart';
import 'package:studyvault/screens/tabs/home_tab.dart';
import 'package:studyvault/screens/tabs/profile_tab.dart';
import 'package:studyvault/screens/tabs/subjects_tab.dart';

import '../provider/bottom_navigation_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Widget> screens = const [
    HomeTab(),
    SubjectsTab(),
    SearchTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BottomNavigationProvider>();

    return Scaffold(
      body: IndexedStack(index: provider.currentIndex, children: screens),
      bottomNavigationBar: const CustomBottomNavigation(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
