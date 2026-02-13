import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/matrix_theme.dart';

enum ViMode { normal, insert }

class ViTextField extends StatefulWidget {
  final TextEditingController controller;
  final int maxLines;

  const ViTextField({
    super.key,
    required this.controller,
    this.maxLines = 8,
  });

  @override
  State<ViTextField> createState() => _ViTextFieldState();
}

class _ViTextFieldState extends State<ViTextField> {
  ViMode _mode = ViMode.insert;
  String? _pendingKey;
  String _yankBuffer = '';
  late final FocusNode _focusNode;
  final List<_UndoEntry> _undoStack = [];

  TextEditingController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);
    _pushUndo();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _pushUndo() {
    _undoStack.add(_UndoEntry(
      text: _ctrl.text,
      offset: _ctrl.selection.baseOffset.clamp(0, _ctrl.text.length),
    ));
  }

  void _popUndo() {
    if (_undoStack.length <= 1) return;
    _undoStack.removeLast();
    final entry = _undoStack.last;
    _ctrl.text = entry.text;
    _ctrl.selection = TextSelection.collapsed(
      offset: entry.offset.clamp(0, _ctrl.text.length),
    );
  }

  int get _offset => _ctrl.selection.baseOffset.clamp(0, _ctrl.text.length);

  void _moveTo(int offset) {
    final clamped = offset.clamp(0, _ctrl.text.length);
    _ctrl.selection = TextSelection.collapsed(offset: clamped);
  }

  int _currentLineStart() {
    final text = _ctrl.text;
    if (text.isEmpty) return 0;
    final o = _offset.clamp(0, text.length);
    int start = text.lastIndexOf('\n', o > 0 ? o - 1 : 0);
    return start == -1 ? 0 : start + 1;
  }

  int _currentLineEnd() {
    final text = _ctrl.text;
    if (text.isEmpty) return 0;
    final o = _offset.clamp(0, text.length);
    int end = text.indexOf('\n', o);
    return end == -1 ? text.length : end;
  }

  String _currentLineText() {
    return _ctrl.text.substring(_currentLineStart(), _currentLineEnd());
  }

  List<int> _lineStarts() {
    final text = _ctrl.text;
    List<int> starts = [0];
    for (int i = 0; i < text.length; i++) {
      if (text[i] == '\n') starts.add(i + 1);
    }
    return starts;
  }

  int _currentLineIndex() {
    final starts = _lineStarts();
    final o = _offset;
    for (int i = starts.length - 1; i >= 0; i--) {
      if (o >= starts[i]) return i;
    }
    return 0;
  }

  void _moveUp() {
    final starts = _lineStarts();
    final lineIdx = _currentLineIndex();
    if (lineIdx == 0) return;
    final col = _offset - starts[lineIdx];
    final prevStart = starts[lineIdx - 1];
    final prevEnd = starts[lineIdx] - 1; // the \n
    final prevLen = prevEnd - prevStart;
    _moveTo(prevStart + col.clamp(0, prevLen));
  }

  void _moveDown() {
    final starts = _lineStarts();
    final lineIdx = _currentLineIndex();
    if (lineIdx >= starts.length - 1) return;
    final col = _offset - starts[lineIdx];
    final nextStart = starts[lineIdx + 1];
    final nextEnd = lineIdx + 2 < starts.length
        ? starts[lineIdx + 2] - 1
        : _ctrl.text.length;
    final nextLen = nextEnd - nextStart;
    _moveTo(nextStart + col.clamp(0, nextLen));
  }

  void _jumpWord() {
    final text = _ctrl.text;
    int o = _offset;
    // skip current word chars
    while (o < text.length && !_isWordBoundary(text[o])) {
      o++;
    }
    // skip whitespace/punctuation
    while (o < text.length && _isWordBoundary(text[o])) {
      o++;
    }
    _moveTo(o);
  }

  void _jumpBackWord() {
    final text = _ctrl.text;
    int o = _offset;
    if (o > 0) o--;
    // skip whitespace/punctuation
    while (o > 0 && _isWordBoundary(text[o])) {
      o--;
    }
    // skip word chars
    while (o > 0 && !_isWordBoundary(text[o - 1])) {
      o--;
    }
    _moveTo(o);
  }

  bool _isWordBoundary(String ch) {
    return ch == ' ' || ch == '\n' || ch == '\t' || ch == '.' || ch == ',';
  }

  void _deleteLine() {
    _pushUndo();
    final text = _ctrl.text;
    final start = _currentLineStart();
    var end = _currentLineEnd();
    // Include the trailing newline if there is one
    if (end < text.length && text[end] == '\n') {
      end++;
    } else if (start > 0) {
      // Leading newline if we're deleting the last line
      _ctrl.text = text.substring(0, start - 1) + text.substring(end);
      _moveTo((start - 1).clamp(0, _ctrl.text.length));
      return;
    }
    _ctrl.text = text.substring(0, start) + text.substring(end);
    _moveTo(start.clamp(0, _ctrl.text.length));
  }

  void _yankLine() {
    _yankBuffer = _currentLineText();
  }

  void _pasteLine() {
    _pushUndo();
    final text = _ctrl.text;
    final end = _currentLineEnd();
    final insert = '\n$_yankBuffer';
    _ctrl.text = text.substring(0, end) + insert + text.substring(end);
    _moveTo(end + 1);
  }

  void _deleteChar() {
    final text = _ctrl.text;
    final o = _offset;
    if (o >= text.length) return;
    _pushUndo();
    _ctrl.text = text.substring(0, o) + text.substring(o + 1);
    _moveTo(o.clamp(0, _ctrl.text.length));
  }

  void _enterInsert({int offsetAdjust = 0, bool atEnd = false, bool atStart = false}) {
    setState(() => _mode = ViMode.insert);
    if (atEnd) {
      _moveTo(_currentLineEnd());
    } else if (atStart) {
      _moveTo(_currentLineStart());
    } else {
      _moveTo((_offset + offsetAdjust).clamp(0, _ctrl.text.length));
    }
  }

  void _openLineBelow() {
    _pushUndo();
    final text = _ctrl.text;
    final end = _currentLineEnd();
    _ctrl.text = '${text.substring(0, end)}\n${text.substring(end)}';
    _moveTo(end + 1);
    setState(() => _mode = ViMode.insert);
  }

  void _openLineAbove() {
    _pushUndo();
    final text = _ctrl.text;
    final start = _currentLineStart();
    if (start == 0) {
      _ctrl.text = '\n$text';
      _moveTo(0);
    } else {
      _ctrl.text = '${text.substring(0, start)}\n${text.substring(start)}';
      _moveTo(start);
    }
    setState(() => _mode = ViMode.insert);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (_mode == ViMode.insert) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _pushUndo();
        setState(() => _mode = ViMode.normal);
        // Move cursor back one position (vi behavior)
        if (_offset > 0) _moveTo(_offset - 1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Normal mode
    final char = event.character;

    // Handle two-key combos
    if (_pendingKey != null) {
      if (char == null) {
        // Ignore non-character keys (modifiers, etc.) while pending
        return KeyEventResult.handled;
      }
      final combo = _pendingKey! + char;
      _pendingKey = null;
      setState(() {});
      switch (combo) {
        case 'gg':
          _moveTo(0);
          return KeyEventResult.handled;
        case 'dd':
          _yankLine();
          _deleteLine();
          return KeyEventResult.handled;
        case 'yy':
          _yankLine();
          return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    // Single key commands
    if (char == 'g' || char == 'd' || char == 'y') {
      _pendingKey = char;
      setState(() {});
      return KeyEventResult.handled;
    }

    switch (char) {
      case 'i':
        _enterInsert();
        return KeyEventResult.handled;
      case 'a':
        _enterInsert(offsetAdjust: 1);
        return KeyEventResult.handled;
      case 'A':
        _enterInsert(atEnd: true);
        return KeyEventResult.handled;
      case 'I':
        _enterInsert(atStart: true);
        return KeyEventResult.handled;
      case 'o':
        _openLineBelow();
        return KeyEventResult.handled;
      case 'O':
        _openLineAbove();
        return KeyEventResult.handled;
      case 'h':
        _moveTo(_offset - 1);
        return KeyEventResult.handled;
      case 'l':
        _moveTo(_offset + 1);
        return KeyEventResult.handled;
      case 'j':
        _moveDown();
        return KeyEventResult.handled;
      case 'k':
        _moveUp();
        return KeyEventResult.handled;
      case 'w':
        _jumpWord();
        return KeyEventResult.handled;
      case 'b':
        _jumpBackWord();
        return KeyEventResult.handled;
      case '0':
        _moveTo(_currentLineStart());
        return KeyEventResult.handled;
      case r'$':
        _moveTo(_currentLineEnd());
        return KeyEventResult.handled;
      case 'G':
        _moveTo(_ctrl.text.length);
        return KeyEventResult.handled;
      case 'p':
        if (_yankBuffer.isNotEmpty) _pasteLine();
        return KeyEventResult.handled;
      case 'u':
        _popUndo();
        return KeyEventResult.handled;
      case 'x':
        _deleteChar();
        return KeyEventResult.handled;
    }

    // Block unrecognized character keys in normal mode, but let
    // special keys (arrows, modifiers, etc.) pass through
    return char != null ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          readOnly: _mode == ViMode.normal,
          showCursor: true,
          style: const TextStyle(
            color: MatrixTheme.primaryGreen,
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          cursorColor: MatrixTheme.primaryGreen,
          cursorWidth: _mode == ViMode.normal ? 8 : 2,
          maxLines: widget.maxLines,
          minLines: widget.maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: MatrixTheme.background,
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: MatrixTheme.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: MatrixTheme.primaryGreen),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _mode == ViMode.normal
              ? '-- NORMAL --${_pendingKey != null ? ' ($_pendingKey)' : ''}'
              : '-- INSERT --',
          style: TextStyle(
            color: MatrixTheme.primaryGreen,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: MatrixTheme.glowShadow(blurRadius: 6),
          ),
        ),
      ],
    );
  }
}

class _UndoEntry {
  final String text;
  final int offset;
  _UndoEntry({required this.text, required this.offset});
}
