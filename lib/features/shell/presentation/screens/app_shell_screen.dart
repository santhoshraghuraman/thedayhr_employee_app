import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thedayhr_employee_app/core/theme/app_theme.dart';
import 'package:thedayhr_employee_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:thedayhr_employee_app/features/chat/presentation/screens/chat_placeholder_screen.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/screens/hrms_dashboard_screen.dart';
import 'package:thedayhr_employee_app/features/shell/presentation/providers/mode_provider.dart';

/// Authenticated application shell providing adaptive HRMS / Chat mode
/// switching while keeping each module's state and navigation stack intact.
class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({super.key});

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  final _hrmsNavigatorKey = GlobalKey<NavigatorState>();
  final _chatNavigatorKey = GlobalKey<NavigatorState>();

  bool _hrmsCanPop = false;
  bool _chatCanPop = false;

  void _refreshCanPop() {
    if (!mounted) return;
    final nextHrms = _hrmsNavigatorKey.currentState?.canPop() ?? false;
    final nextChat = _chatNavigatorKey.currentState?.canPop() ?? false;
    if (nextHrms != _hrmsCanPop || nextChat != _chatCanPop) {
      setState(() {
        _hrmsCanPop = nextHrms;
        _chatCanPop = nextChat;
      });
    }
  }

  NavigatorState? _navigatorForMode(AppMode mode) {
    return switch (mode) {
      AppMode.hrms => _hrmsNavigatorKey.currentState,
      AppMode.chat => _chatNavigatorKey.currentState,
    };
  }

  void _onSelectMode(AppMode nextMode) {
    final currentMode = ref.read(appModeProvider);
    if (currentMode == nextMode) {
      _navigatorForMode(nextMode)?.popUntil((route) => route.isFirst);
      return;
    }
    ref.read(appModeProvider.notifier).setMode(nextMode);
  }

  @override
  Widget build(BuildContext context) {
    final activeMode = ref.watch(appModeProvider);
    final activeBranchCanPop =
        activeMode == AppMode.hrms ? _hrmsCanPop : _chatCanPop;

    final modeLabel = activeMode == AppMode.hrms ? 'HRMS Mode' : 'Chat Mode';
    final modeColor = activeMode == AppMode.hrms
        ? AppTheme.primaryColor
        : AppTheme.secondaryColor;

    return PopScope(
      canPop: !activeBranchCanPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navigatorForMode(activeMode);
        if (nav != null && nav.canPop()) {
          nav.pop();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useRail = constraints.maxWidth >= 720;

          final contentStack = IndexedStack(
            index: activeMode.index,
            children: [
              _BranchNavigator(
                navigatorKey: _hrmsNavigatorKey,
                onStackChanged: _refreshCanPop,
                rootBuilder: (_) => const HrmsDashboardScreen(),
              ),
              _BranchNavigator(
                navigatorKey: _chatNavigatorKey,
                onStackChanged: _refreshCanPop,
                rootBuilder: (_) => const ChatPlaceholderScreen(),
              ),
            ],
          );

          return Scaffold(
            appBar: AppBar(
              titleSpacing: 16,
              title: Row(
                children: [
                  const Text(
                    'TheDayHR',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      key: ValueKey(activeMode),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: modeColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        modeLabel,
                        key: const Key('shell_active_mode_badge'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: modeColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton.icon(
                  key: const Key('shell_logout_button'),
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign Out'),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: useRail
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: activeMode.index,
                        onDestinationSelected: (index) =>
                            _onSelectMode(AppMode.values[index]),
                        labelType: NavigationRailLabelType.all,
                        backgroundColor: AppTheme.surfaceCard,
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.badge_outlined),
                            selectedIcon: Icon(Icons.badge),
                            label: Text('HRMS'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.chat_bubble_outline_rounded),
                            selectedIcon: Icon(Icons.chat_bubble_rounded),
                            label: Text('Chat'),
                          ),
                        ],
                      ),
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AppTheme.borderSubtle,
                      ),
                      Expanded(child: contentStack),
                    ],
                  )
                : contentStack,
            bottomNavigationBar: useRail
                ? null
                : NavigationBar(
                    key: const Key('shell_bottom_navigation'),
                    selectedIndex: activeMode.index,
                    onDestinationSelected: (index) =>
                        _onSelectMode(AppMode.values[index]),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.badge_outlined),
                        selectedIcon: Icon(Icons.badge),
                        label: 'HRMS',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.chat_bubble_outline_rounded),
                        selectedIcon: Icon(Icons.chat_bubble_rounded),
                        label: 'Chat',
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _BranchNavigator extends StatefulWidget {
  const _BranchNavigator({
    required this.navigatorKey,
    required this.onStackChanged,
    required this.rootBuilder,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback onStackChanged;
  final WidgetBuilder rootBuilder;

  @override
  State<_BranchNavigator> createState() => _BranchNavigatorState();
}

class _BranchNavigatorState extends State<_BranchNavigator> {
  late final _BranchObserver _observer = _BranchObserver(widget.onStackChanged);

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: widget.navigatorKey,
      observers: [_observer],
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: widget.rootBuilder,
      ),
    );
  }
}

class _BranchObserver extends NavigatorObserver {
  _BranchObserver(this.onChanged);

  final VoidCallback onChanged;

  void _notifyPostFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => onChanged());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _notifyPostFrame();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _notifyPostFrame();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _notifyPostFrame();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _notifyPostFrame();
  }
}

