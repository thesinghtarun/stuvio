import 'package:bottom_bar_matu/bottom_bar/bottom_bar_bubble.dart';
import 'package:bottom_bar_matu/bottom_bar_double_bullet/bottom_bar_double_bullet.dart';
import 'package:bottom_bar_matu/bottom_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../provider/bottom_navigation_provider.dart';

class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BottomNavigationProvider>();

    return BottomBarDoubleBullet(
      color: Colors.deepPurple,
      selectedIndex: provider.currentIndex,
      onSelect: provider.changeIndex,
      items: [
        BottomBarItem(iconData: Icons.home_rounded, label: "Home"),
        BottomBarItem(iconData: Icons.menu_book_rounded, label: "Subjects"),
        BottomBarItem(iconData: Icons.search, label: "Search"),
        BottomBarItem(iconData: Icons.person, label: "Profile"),
      ],
    );

    // return SalomonBottomBar(
    //   currentIndex: provider.currentIndex,
    //   onTap: provider.changeIndex,
    //   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    //   itemPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    //   items: [
    //     SalomonBottomBarItem(
    //       icon: const Icon(Icons.home_rounded),
    //       title: const Text("Home"),
    //       selectedColor: Colors.blue,
    //     ),
    //     SalomonBottomBarItem(
    //       icon: const Icon(Icons.menu_book_rounded),
    //       title: const Text("Subjects"),
    //       selectedColor: Colors.deepPurple,
    //     ),
    //     // SalomonBottomBarItem(
    //     //   icon: const Icon(Icons.file_upload),
    //     //   title: const Text("Add"),
    //     //   selectedColor: Colors.deepPurple,
    //     // ),
    //     SalomonBottomBarItem(
    //       icon: const Icon(Icons.search),
    //       title: const Text("Search"),
    //       selectedColor: Colors.orange,
    //     ),
    //     SalomonBottomBarItem(
    //       icon: const Icon(Icons.person),
    //       title: const Text("Profile"),
    //       selectedColor: Colors.green,
    //     ),
    //   ],
    // );
  }
}
