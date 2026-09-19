import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'sidebar_drawer.dart';
import 'chat_view.dart';
import 'search_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isMetaOrCtrl = HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    if (!mounted) return false;
    final provider = context.read<ChatProvider>();

    // Cmd + Shift + O -> New Chat
    if (isMetaOrCtrl && isShift &&
        (event.logicalKey == LogicalKeyboardKey.keyO ||
         event.logicalKey == LogicalKeyboardKey.keyN ||
         event.logicalKey == LogicalKeyboardKey.keyT)) {
      provider.startNewChat();
      return true;
    }

    // Cmd + B -> Toggle Drawer
    if (isMetaOrCtrl && !isShift && event.logicalKey == LogicalKeyboardKey.keyB) {
      if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
        _scaffoldKey.currentState?.closeDrawer();
      } else {
        _scaffoldKey.currentState?.openDrawer();
      }
      return true;
    }

    // Cmd + K -> Global Search Modal
    if (isMetaOrCtrl && !isShift && event.logicalKey == LogicalKeyboardKey.keyK) {
      showDialog(
        context: context,
        builder: (_) => const SearchDialog(),
      );
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: true,
      drawer: const SidebarDrawer(),
      body: const ChatView(),
    );
  }
}
