import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../provider/bottom_navigation_provider.dart';

class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BottomNavigationProvider>();

    return SalomonBottomBar(
      currentIndex: provider.currentIndex,
      onTap: provider.changeIndex,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      items: [
        SalomonBottomBarItem(
          icon: const Icon(Icons.home_rounded),
          title: const Text("Home"),
          selectedColor: Colors.blue,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.menu_book_rounded),
          title: const Text("Subjects"),
          selectedColor: Colors.deepPurple,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.search),
          title: const Text("Search"),
          selectedColor: Colors.orange,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.note_alt_rounded),
          title: const Text("Notes"),
          selectedColor: Colors.green,
        ),
      ],
    );
  }
}
