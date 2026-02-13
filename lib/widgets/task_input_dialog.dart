import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/task.dart';
import '../theme/matrix_theme.dart';
import 'vi_text_field.dart';

class TaskInputDialog extends StatefulWidget {
  final Task? existingTask;

  const TaskInputDialog({super.key, this.existingTask});

  @override
  State<TaskInputDialog> createState() => _TaskInputDialogState();
}

class _TaskInputDialogState extends State<TaskInputDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _progressController;
  Priority _priority = Priority.medium;
  DateTime? _dueDate;
  late bool _showPreview = widget.existingTask != null;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingTask?.title ?? '');
    _descController =
        TextEditingController(text: widget.existingTask?.description ?? '');
    _progressController =
        TextEditingController(text: widget.existingTask?.progress ?? '');
    if (_isEditing) {
      _priority = widget.existingTask!.priority;
      _dueDate = widget.existingTask!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: MatrixTheme.darkTheme.copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: MatrixTheme.background,
              surfaceTintColor: Colors.transparent,
              headerForegroundColor: MatrixTheme.primaryGreen,
              dayForegroundColor:
                  WidgetStateProperty.all(MatrixTheme.primaryGreen),
              yearForegroundColor:
                  WidgetStateProperty.all(MatrixTheme.primaryGreen),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    Navigator.of(context).pop({
      'title': title,
      'description': _descController.text.trim(),
      'priority': _priority,
      'dueDate': _dueDate,
      'progress': _progressController.text.trim(),
    });
  }

  Widget _buildToggleButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _showPreview = label == 'PREVIEW'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? MatrixTheme.primaryGreen.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? MatrixTheme.primaryGreen
                : MatrixTheme.primaryGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? MatrixTheme.primaryGreen : MatrixTheme.dimGreen,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows:
                isActive ? MatrixTheme.glowShadow(blurRadius: 6) : null,
          ),
        ),
      ),
    );
  }

  late final MarkdownStyleSheet _markdownStyle = MarkdownStyleSheet(
        p: const TextStyle(color: MatrixTheme.primaryGreen, fontSize: 14),
        code: const TextStyle(
          color: MatrixTheme.primaryGreen,
          backgroundColor: MatrixTheme.surfaceColor,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: MatrixTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: MatrixTheme.primaryGreen.withValues(alpha: 0.2),
          ),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        h1: TextStyle(
          color: MatrixTheme.primaryGreen,
          fontWeight: FontWeight.bold,
          fontSize: 22,
          shadows: MatrixTheme.glowShadow(blurRadius: 8),
        ),
        h2: TextStyle(
          color: MatrixTheme.primaryGreen,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          shadows: MatrixTheme.glowShadow(blurRadius: 8),
        ),
        h3: TextStyle(
          color: MatrixTheme.primaryGreen,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          shadows: MatrixTheme.glowShadow(blurRadius: 6),
        ),
        h4: TextStyle(
          color: MatrixTheme.primaryGreen,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          shadows: MatrixTheme.glowShadow(blurRadius: 6),
        ),
        h5: TextStyle(
          color: MatrixTheme.primaryGreen,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          shadows: MatrixTheme.glowShadow(blurRadius: 4),
        ),
        h6: TextStyle(
          color: MatrixTheme.primaryGreen,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          shadows: MatrixTheme.glowShadow(blurRadius: 4),
        ),
        a: const TextStyle(color: MatrixTheme.dimGreen),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: MatrixTheme.dimGreen,
              width: 3,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
        listBullet: const TextStyle(color: MatrixTheme.primaryGreen),
        em: const TextStyle(
          color: MatrixTheme.primaryGreen,
          fontStyle: FontStyle.italic,
        ),
        strong: const TextStyle(
          color: MatrixTheme.primaryGreen,
          fontWeight: FontWeight.bold,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: MatrixTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
              color: MatrixTheme.primaryGreen.withValues(alpha: 0.3)),
          left: BorderSide(
              color: MatrixTheme.primaryGreen.withValues(alpha: 0.3)),
          right: BorderSide(
              color: MatrixTheme.primaryGreen.withValues(alpha: 0.3)),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MatrixTheme.dimGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isEditing ? '> EDIT TASK_' : '> NEW TASK_',
              style: TextStyle(
                color: MatrixTheme.primaryGreen,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: MatrixTheme.glowShadow(blurRadius: 10),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: MatrixTheme.primaryGreen),
              cursorColor: MatrixTheme.primaryGreen,
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              style: const TextStyle(color: MatrixTheme.primaryGreen),
              cursorColor: MatrixTheme.primaryGreen,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Priority>(
                    initialValue: _priority,
                    dropdownColor: MatrixTheme.background,
                    style: const TextStyle(color: MatrixTheme.primaryGreen),
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: Priority.values.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _priority = v);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Due Date'),
                      child: Text(
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                            : 'None',
                        style: TextStyle(
                          color: _dueDate != null
                              ? MatrixTheme.primaryGreen
                              : MatrixTheme.dimGreen,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '> PROGRESS_',
              style: TextStyle(
                color: MatrixTheme.primaryGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: MatrixTheme.glowShadow(blurRadius: 8),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildToggleButton('WRITE', !_showPreview),
                const SizedBox(width: 8),
                _buildToggleButton('PREVIEW', _showPreview),
              ],
            ),
            const SizedBox(height: 8),
            if (_showPreview)
              Container(
                constraints: const BoxConstraints(minHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MatrixTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: MatrixTheme.primaryGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: _progressController.text.isEmpty
                    ? Text(
                        'Nothing to preview',
                        style: TextStyle(
                          color: MatrixTheme.dimGreen,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : MarkdownBody(
                        data: _progressController.text,
                        styleSheet: _markdownStyle,
                      ),
              )
            else
              ViTextField(
                controller: _progressController,
                maxLines: 8,
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                        color:
                            MatrixTheme.primaryGreen.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MatrixTheme.primaryGreen,
                    foregroundColor: MatrixTheme.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_isEditing ? 'UPDATE' : 'CREATE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
