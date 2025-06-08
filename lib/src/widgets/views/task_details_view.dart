 
// lib/src/widgets/views/task_details_view.dart
import 'package:arcane/src/widgets/completed_task_card.dart';
import 'package:arcane/src/widgets/dialogs/ai_task_generation_dialog.dart';
import 'package:arcane/src/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class TaskDetailsView extends StatefulWidget {
  const TaskDetailsView({super.key});

  @override
  State<TaskDetailsView> createState() => _TaskDetailsViewState();
}

class _TaskDetailsViewState extends State<TaskDetailsView> {
  final _newTaskNameController = TextEditingController();
  bool _newTaskIsCountable = false;
  final _newTaskTargetCountController = TextEditingController(text: '10');
  bool _showCompleted = true;

  @override
  void dispose() {
    _newTaskNameController.dispose();
    _newTaskTargetCountController.dispose();
    super.dispose();
  }

  void _handleAddTask(GameProvider gameProvider, Project project) {
    if (_newTaskNameController.text.trim().isNotEmpty) {
      final taskData = {
        'name': _newTaskNameController.text.trim(),
        'isCountable': _newTaskIsCountable,
        'targetCount': _newTaskIsCountable
            ? (int.tryParse(_newTaskTargetCountController.text) ?? 1)
            : 0,
      };
      gameProvider.addTask(project.id, taskData);
      _newTaskNameController.clear();
      if (mounted) {
        setState(() {
          _newTaskIsCountable = false;
          _newTaskTargetCountController.text = '10';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final project = gameProvider.getSelectedProject();
        final theme = Theme.of(context);

        if (project == null) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.textBoxSearchOutline,
                    size: 56,
                    color: (gameProvider.getSelectedProject()?.color ??
                        AppTheme.fortniteBlue)),
                const SizedBox(height: 16),
                Text('Select a Project',
                    style: theme.textTheme.displaySmall?.copyWith(
                        color: (gameProvider.getSelectedProject()?.color ??
                            AppTheme.fortniteBlue))),
                const SizedBox(height: 8),
                Text(
                    'Tasks for the selected project will appear here.',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppTheme.fnTextSecondary),
                    textAlign: TextAlign.center),
              ],
            ),
          ));
        }

        final pendingTasks =
            project.tasks.where((t) => !t.completed).toList();
        final completedTasks =
            project.tasks.where((t) => t.completed).toList();
        final timeProgressPercent =
            (project.dailyTimeSpent / dailyTaskGoalMinutes.toDouble())
                .clamp(0.0, 1.0);
        Color timeProgressColor =
            (gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue);
        if (project.dailyTimeSpent >= dailyTaskGoalMinutes) {
          timeProgressColor = AppTheme.fnAccentGreen;
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildProjectHeaderCard(theme, project, timeProgressColor,
                        timeProgressPercent, completedTasks.length, project.tasks.length),
                    const Divider(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 8.0),
                      child: Text('Pending Tasks',
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: AppTheme.fontDisplay,
                              color: AppTheme.fnTextPrimary,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (pendingTasks.isEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 24.0),
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme.fnBorderColor
                                  .withAlpha((255 * 0.4).round()),
                              width: 1,
                              style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(16),
                          color: AppTheme.fnBgDark
                              .withAlpha((255 * 0.3).round()),
                        ),
                        child: Center(
                            child: Text(
                                'No pending tasks. Add one manually below or use the AI generator.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.fnTextSecondary
                                        .withAlpha((255 * 0.8).round()),
                                    fontStyle: FontStyle.italic))),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pendingTasks.length,
                        itemBuilder: (ctx, index) {
                          final task = pendingTasks[index];
                          return TaskCard(
                              key: ValueKey(task.id),
                              project: project,
                              task: task);
                        },
                      ),
                    _buildAddNewTaskCard(theme, gameProvider, project),
                    const SizedBox(height: 16),
                    if (completedTasks.isNotEmpty)
                      _buildCompletedTasksSection(
                          theme, completedTasks, project),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedTasksSection(
      ThemeData theme, List<Task> completedTasks, Project project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        InkWell(
          onTap: () => setState(() => _showCompleted = !_showCompleted),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Completed Tasks (${completedTasks.length})',
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: AppTheme.fontDisplay,
                          color: AppTheme.fnTextSecondary,
                          fontWeight: FontWeight.w600)),
                ),
                Icon(
                  _showCompleted
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: AppTheme.fnTextSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_showCompleted)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: completedTasks.length,
            itemBuilder: (ctx, index) {
              final task = completedTasks[index];
              return CompletedTaskCard(
                  key: ValueKey('completed-${task.id}'),
                  project: project,
                  task: task);
            },
          ),
      ],
    );
  }

  Widget _buildProjectHeaderCard(
      ThemeData theme,
      Project project,
      Color timeProgressColor,
      double timeProgressPercent,
      int completedTasksCount,
      int totalTasksCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${project.theme.toUpperCase()} PROJECT',
                    style: TextStyle(
                        color: project.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8)),
                Chip(
                  label: const Text('ACTIVE'),
                  backgroundColor: AppTheme.fnAccentRed,
                  labelStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(project.name,
                style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 28,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(project.description,
                style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.5)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: timeProgressColor.withAlpha((255 * 0.05).round()),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: timeProgressColor.withAlpha((255 * 0.15).round())),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Time Logged: ${project.dailyTimeSpent}m / ${dailyTaskGoalMinutes}m Goal',
                            style: const TextStyle(
                                color: Color(0xFFCBD5E1), fontSize: 14)),
                        const SizedBox(height: 8),
                        Container(
                          height: 6,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                              color: timeProgressColor
                                  .withAlpha((255 * 0.2).round()),
                              borderRadius: BorderRadius.circular(3)),
                          child: LinearProgressIndicator(
                              value: timeProgressPercent,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  timeProgressColor)),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  const Color(0xFFF59E0B).withAlpha((255 * 0.3).round()),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(project.streak.toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Divider(
                  color: const Color(0xFF94A3B8).withAlpha((255 * 0.3).round()),
                  height: 1),
            ),
            Center(
              child: Column(
                children: [
                  Text('TASK TRACKING:',
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.fnTextSecondary,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                      '$completedTasksCount / $totalTasksCount modules completed',
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewTaskCard(
      ThemeData theme, GameProvider gameProvider, Project project) {
    return Card(
      margin: const EdgeInsets.only(top: 24, left: 0, right: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Task',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: AppTheme.fontDisplay,
                    color: AppTheme.fnTextPrimary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _newTaskNameController,
              decoration: const InputDecoration(hintText: 'Task objective...'),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontSize: 14, color: AppTheme.fnTextPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _newTaskIsCountable,
                  onChanged: (val) =>
                      setState(() => _newTaskIsCountable = val ?? false),
                  activeColor: (gameProvider.getSelectedProject()?.color ??
                      AppTheme.fortniteBlue),
                  checkColor: AppTheme.fnBgDark,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                      color: (gameProvider.getSelectedProject()?.color ??
                              AppTheme.fortniteBlue)
                          .withAlpha((255 * 0.7).round()),
                      width: 1.5),
                ),
                const Flexible(
                    child: Text('Is it countable?',
                        style: TextStyle(
                            color: AppTheme.fnTextSecondary,
                            fontSize: 13,
                            fontFamily: AppTheme.fontBody))),
                const SizedBox(width: 12),
                if (_newTaskIsCountable)
                  Expanded(
                    child: TextField(
                      controller: _newTaskTargetCountController,
                      decoration: const InputDecoration(
                          labelText: 'Target #',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          fontSize: 13,
                          fontFamily: AppTheme.fontBody,
                          color: AppTheme.fnTextPrimary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(MdiIcons.plusBoxOutline, size: 18),
                    label: const Text('ADD TASK'),
                    onPressed: () => _handleAddTask(gameProvider, project),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  child: Icon(MdiIcons.creation, size: 18),
                  onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) =>
                          AITaskGenerationDialog(project: project)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.fortnitePurple,
                    minimumSize: const Size(40, 40),
                  ),
                  
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
 