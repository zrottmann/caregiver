import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isCaregiver;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isCaregiver,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        onTap(index);
        _navigateToRoute(context, index);
      },
      items: _getNavItems(),
    );
  }

  List<BottomNavigationBarItem> _getNavItems() {
    if (isCaregiver) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Schedule',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
  }

  void _navigateToRoute(BuildContext context, int index) {
    if (isCaregiver) {
      switch (index) {
        case 0:
          context.go('/home');
          break;
        case 1:
          // Schedule - not implemented yet
          break;
        case 2:
          context.push('/chats');
          break;
        case 3:
          context.push('/profile');
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go('/home');
          break;
        case 1:
          context.push('/search');
          break;
        case 2:
          context.push('/chats');
          break;
        case 3:
          context.push('/profile');
          break;
      }
    }
  }
}