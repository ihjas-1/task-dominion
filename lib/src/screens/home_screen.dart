import 'package:arcane/src/widgets/break_timer_banner.dart';
import 'package:arcane/src/widgets/dialogs/username_prompt_dialog.dart';
import 'package:arcane/src/widgets/views/logbook_view.dart';
import 'package:arcane/src/widgets/views/skills_view.dart';
import 'package:flutter/material.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/widgets/header_widget.dart';
import 'package:arcane/src/widgets/project_navigation_drawer.dart';
import 'package:arcane/src/widgets/skill_drawer.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/widgets/views/task_details_view.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:arcane/src/screens/chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GameProvider _gameProvider;
  bool _isUsernameDialogShowing = false;
  bool _isTutorialShowing = false;
  int _mobileSelectedIndex = 0; // 0: Tasks, 1: Logbook, 2: Skills

  @override
  void initState() {
    super.initState();
    _gameProvider = Provider.of<GameProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
    _gameProvider.addListener(_handleProviderChanges);
  }
  
  void _initializeScreen() {
     if (_gameProvider.selectedProjectId == null &&
          _gameProvider.projects.isNotEmpty) {
        _gameProvider.setSelectedProjectId(_gameProvider.projects.first.id);
      }
      _checkAndPromptForUsername(_gameProvider);
      _checkAndShowTutorial(_gameProvider);
  }

  void _handleProviderChanges() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    _checkAndPromptForUsername(gameProvider);
    _checkAndShowTutorial(gameProvider);
  }

  void _checkAndShowTutorial(GameProvider gameProvider) {
     if (mounted && !gameProvider.settings.tutorialShown && !_isTutorialShowing &&
        !gameProvider.authLoading && !gameProvider.isDataLoadingAfterLogin && !_isUsernameDialogShowing) {
       setState(() => _isTutorialShowing = true);
       _startTutorial(context).then((_) {
         if (mounted) setState(() => _isTutorialShowing = false);
       });
     }
  }

  void _checkAndPromptForUsername(GameProvider gameProvider) {
    if (mounted &&
        gameProvider.isUsernameMissing &&
        gameProvider.currentUser != null &&
        !_isUsernameDialogShowing &&
        !gameProvider.authLoading &&
        !gameProvider.isDataLoadingAfterLogin) {
      setState(() => _isUsernameDialogShowing = true);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => const UsernamePromptDialog(),
      ).then((_) {
        if (mounted) setState(() => _isUsernameDialogShowing = false);
      });
    }
  }

  @override
  void dispose() {
    _gameProvider.removeListener(_handleProviderChanges);
    super.dispose();
  }

  Widget _buildLogbookFab(BuildContext context, ThemeData theme) {
    return FloatingActionButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatbotScreen())),
      tooltip: 'Advisor',
      backgroundColor: theme.colorScheme.secondary,
      foregroundColor: ThemeData.estimateBrightnessForColor(theme.colorScheme.secondary) == Brightness.dark
          ? AppTheme.fnTextPrimary
          : AppTheme.fnBgDark,
      child: Icon(MdiIcons.robotHappyOutline),
    );
  }

  void _showTakeBreakDialog(BuildContext context, GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Take a Break', style: TextStyle(color: (gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Spend energy to take a break and recover focus.'),
            const SizedBox(height: 16),
            _buildBreakButton(ctx, gameProvider, 5, '5-min break'),
            _buildBreakButton(ctx, gameProvider, 15, '15-min break'),
            _buildBreakButton(ctx, gameProvider, 30, '30-min break'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Widget _buildBreakButton(BuildContext context, GameProvider gameProvider, int minutes, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton(
        onPressed: gameProvider.playerEnergy >= minutes ? () {
          gameProvider.takeBreak(minutes);
          Navigator.of(context).pop();
        } : null,
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40), disabledBackgroundColor: AppTheme.fnBgLight),
        child: Text('$text'),
      ),
    );
  }

  Widget _buildTaskDetailsFab(BuildContext context, ThemeData theme) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    return FloatingActionButton(
      onPressed: () => _showTakeBreakDialog(context, gameProvider),
      tooltip: 'Take Break',
      backgroundColor: theme.colorScheme.secondary,
      foregroundColor: ThemeData.estimateBrightnessForColor(theme.colorScheme.secondary) == Brightness.dark
          ? AppTheme.fnTextPrimary
          : AppTheme.fnBgDark,
      child: Icon(MdiIcons.coffeeOutline),
    );
  }
  
  Future<void> _startTutorial(BuildContext context) async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    await _showTutorialStep(
      title: 'Welcome to Arcane!',
      content: 'This is your command center for turning goals into achievements. Let\'s walk through the key features.',
      isFirst: true
    );
    await _showTutorialStep(
      title: 'Projects Panel (Left)',
      content: 'Projects are your major goals (e.g., "Learn a New Skill", "Fitness Journey"). Tap the list icon on mobile, or see it on the left on desktop. Create new projects and switch between them here.',
    );
     await _showTutorialStep(
      title: 'Task View (Center)',
      content: 'This is where you manage the specific tasks for your selected project. You can add tasks, track time with the session timer, and break them down into smaller checkpoints.',
    );
     await _showTutorialStep(
      title: 'Skills Panel (Right)',
      content: 'Completing tasks and checkpoints earns you XP in related skills. Level up your skills to see your progress and unlock new potential! View your skills by tapping the atom icon.',
    );
     await _showTutorialStep(
      title: 'The Header',
      content: 'At the top, you\'ll find your vital stats: Coins, Energy, and your current Player Level & XP. Use energy for breaks and coins to replenish energy.',
    );
    await _showTutorialStep(
      title: 'Ready to Begin?',
      content: 'You\'re all set to start your journey. Define your projects, break them into tasks, and start conquering your goals!',
      isLast: true,
      onNext: () {
        gameProvider.completeTutorial();
      }
    );
  }

  Future<void> _showTutorialStep({
    required String title, 
    required String content, 
    bool isFirst = false, 
    bool isLast = false,
    VoidCallback? onNext,
  }) async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(children: [Icon(MdiIcons.schoolOutline, color: Theme.of(context).primaryColor), const SizedBox(width: 8), Text(title)]),
        content: Text(content, style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          if(!isFirst)
            TextButton(child: const Text('Back'), onPressed: (){
              // This simple implementation doesn't support 'back'.
              // A more complex state management (like a tutorial provider) would be needed.
            },),
          ElevatedButton(
            child: Text(isLast ? 'FINISH' : 'NEXT'),
            onPressed: () {
              onNext?.call();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      )
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 900;

    final gameProvider = context.watch<GameProvider>();
    final Color currentProjectColor =
        gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue;
    final ThemeData dynamicTheme =
        AppTheme.getThemeData(primaryAccent: currentProjectColor);

    const List<Widget> mobileViews = [TaskDetailsView(), LogbookView(), SkillsView()];
    const List<String> viewLabels = ["TASKS", "LOGBOOK", "SKILLS"];

    return Theme(
      data: dynamicTheme,
      child: Scaffold(
        backgroundColor: AppTheme.fnBgDark, // Set a base background color
        body: Stack(
          children: [
            // Layer 1: Animated Gradient Background
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [currentProjectColor.withOpacity(0.1), AppTheme.fnBgDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Layer 2: Main Content
            Column(
              children: [
                if (gameProvider.breakEndTime != null) const BreakTimerBanner(),
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        HeaderWidget(
                          currentViewLabel: viewLabels[_mobileSelectedIndex],
                          isMobile: !isLargeScreen,
                        ),
                        Expanded(
                          child: isLargeScreen
                              ? Row(
                                  children: [
                                    Container(
                                      width: 280,
                                      decoration: BoxDecoration(
                                        color: dynamicTheme.cardTheme.color,
                                        border: Border(right: BorderSide(color: dynamicTheme.dividerTheme.color ?? AppTheme.fnBorderColor, width: 1)),
                                      ),
                                      child: const ProjectNavigationDrawer(),
                                    ),
                                     const Expanded(child: Center(child:  TaskDetailsView())),
                                     Container(
                                      width: 280,
                                      decoration: BoxDecoration(
                                        color: dynamicTheme.cardTheme.color,
                                        border: Border(left: BorderSide(color: dynamicTheme.dividerTheme.color ?? AppTheme.fnBorderColor, width: 1)),
                                      ),
                                      child: const SkillDrawer(),
                                    ),
                                  ],
                                )
                              : IndexedStack(index: _mobileSelectedIndex, children: mobileViews),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        drawer: isLargeScreen ? null : const ProjectNavigationDrawer(),
        endDrawer: isLargeScreen ? null : const SkillDrawer(),
        floatingActionButton: !isLargeScreen && _mobileSelectedIndex == 0
            ? _buildTaskDetailsFab(context, dynamicTheme)
            : (!isLargeScreen && _mobileSelectedIndex == 1 ? _buildLogbookFab(context, dynamicTheme) : null),
        bottomNavigationBar: isLargeScreen ? null : BottomNavigationBar(
          items:  <BottomNavigationBarItem>[
             BottomNavigationBarItem(icon: Icon(MdiIcons.target), label: 'Tasks'),
             BottomNavigationBarItem(icon: Icon(MdiIcons.bookOpenVariant), label: 'Logbook'),
             BottomNavigationBarItem(icon: Icon(MdiIcons.atom), label: 'Skills'),
          ],
          currentIndex: _mobileSelectedIndex,
          onTap: (index) => setState(() => _mobileSelectedIndex = index),
        ),
      ),
    );
  }
}