import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_status.dart';
import '../providers/sobriety_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sobrietyProvider);
    final notifier = ref.read(sobrietyProvider.notifier);

    final history = state.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          final isSober = item.status == DayStatus.sober;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                // ─── Status row ─────────────────────────────────────────────
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: isSober
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                    child: Icon(
                      isSober ? Icons.check : Icons.close,
                      color: isSober ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(item.date.toString().split(' ')[0]),
                  subtitle: Text(
                    isSober ? "Sober" : "Drank",
                    style: TextStyle(
                      color: isSober
                          ? Colors.green.withValues(alpha: 0.8)
                          : Colors.red.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  // Tap the row to toggle sober/drank (existing behaviour)
                  onTap: () {
                    notifier.checkIn(
                      item.date,
                      isSober ? DayStatus.drank : DayStatus.sober,
                    );
                  },
                ),

                // ─── Note area ───────────────────────────────────────────────
                _NoteRow(
                  date: item.date,
                  existingNote: item.note,
                  notifier: notifier,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Note row ─────────────────────────────────────────────────────────────────

class _NoteRow extends StatefulWidget {
  final DateTime date;
  final String? existingNote;
  final SobrietyNotifier notifier;

  const _NoteRow({
    required this.date,
    required this.existingNote,
    required this.notifier,
  });

  @override
  State<_NoteRow> createState() => _NoteRowState();
}

class _NoteRowState extends State<_NoteRow> {
  bool _editing = false;
  late TextEditingController _controller;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingNote ?? '');
  }

  @override
  void didUpdateWidget(_NoteRow old) {
    super.didUpdateWidget(old);
    // Keep controller in sync if the note was changed from outside
    if (old.existingNote != widget.existingNote && !_editing) {
      _controller.text = widget.existingNote ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  Future<void> _save() async {
    await widget.notifier.updateNote(widget.date, _controller.text);
    if (mounted) setState(() => _editing = false);
    _focus.unfocus();
  }

  void _cancel() {
    _controller.text = widget.existingNote ?? '';
    setState(() => _editing = false);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasNote =
        widget.existingNote != null && widget.existingNote!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: _editing
          ? _EditingView(
              controller: _controller,
              focus: _focus,
              onSave: _save,
              onCancel: _cancel,
            )
          : _DisplayView(
              note: widget.existingNote,
              hasNote: hasNote,
              onEdit: _startEditing,
            ),
    );
  }
}

// ─── Display state ────────────────────────────────────────────────────────────

class _DisplayView extends StatelessWidget {
  final String? note;
  final bool hasNote;
  final VoidCallback onEdit;

  const _DisplayView({
    required this.note,
    required this.hasNote,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (hasNote) {
      return GestureDetector(
        onTap: onEdit,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.notes_outlined,
                  size: 14, color: Colors.white.withValues(alpha: 0.35)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
              Icon(Icons.edit_outlined,
                  size: 14, color: Colors.white.withValues(alpha: 0.25)),
            ],
          ),
        ),
      );
    }

    // No note yet — show a quiet "add note" prompt
    return GestureDetector(
      onTap: onEdit,
      child: Row(
        children: [
          Icon(Icons.add, size: 14, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(width: 4),
          Text(
            "Add a note",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Editing state ────────────────────────────────────────────────────────────

class _EditingView extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditingView({
    required this.controller,
    required this.focus,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          focusNode: focus,
          maxLines: null,
          minLines: 2,
          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
          decoration: InputDecoration(
            hintText: "What are you feeling or thinking today?",
            hintStyle:
                TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white38,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text("Cancel", style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.black87,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Save", style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}
