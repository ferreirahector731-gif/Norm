import 'dart:convert';

import '../../notes/domain/note_model.dart';
import '../../sheets/domain/sheet_block.dart';
import '../../charts/domain/chart_block.dart';
import '../../tasks/domain/task_block.dart';
import 'package:uuid/uuid.dart';

class LinkEntry {
  final String id;
  int targetNoteId;
  String? label;
  String? description;
  DateTime createdAt;

  LinkEntry({
    String? id,
    required this.targetNoteId,
    this.label,
    this.description,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetNoteId': targetNoteId,
        'label': label,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LinkEntry.fromJson(Map<String, dynamic> json) => LinkEntry(
        id: json['id'] as String?,
        targetNoteId: json['targetNoteId'] as int? ?? 0,
        label: json['label'] as String?,
        description: json['description'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
}

class LinkBlock {
  static const String marker = '__norm_type__';
  static const String typeValue = 'link';

  String title;
  List<LinkEntry> outgoingLinks;

  LinkBlock({
    this.title = 'Conexiones',
    List<LinkEntry>? outgoingLinks,
  }) : outgoingLinks = outgoingLinks ?? [];

  int get outgoingCount => outgoingLinks.length;

  void addLink(int targetNoteId, {String? label, String? description}) {
    if (hasLinkTo(targetNoteId)) return;
    outgoingLinks.add(LinkEntry(
      targetNoteId: targetNoteId,
      label: label,
      description: description,
    ));
  }

  void removeLink(String linkId) {
    outgoingLinks.removeWhere((l) => l.id == linkId);
  }

  bool hasLinkTo(int targetNoteId) {
    return outgoingLinks.any((l) => l.targetNoteId == targetNoteId);
  }

  void updateLabel(String linkId, String? label) {
    final idx = outgoingLinks.indexWhere((l) => l.id == linkId);
    if (idx >= 0) outgoingLinks[idx].label = label;
  }

  static List<NoteWithLink> findBacklinks(NoteModel currentNote, List<NoteModel> allNotes) {
    final results = <NoteWithLink>[];
    for (final note in allNotes) {
      if (note.id == currentNote.id) continue;
      if (TaskBlock.isTask(note.contentJson)) {
        final block = TaskBlock.decode(note.contentJson);
        if (block.tasks.any((t) =>
            t.title.toLowerCase().contains(currentNote.title.toLowerCase()))) {
          results.add(NoteWithLink(note: note, matchType: 'mención'));
        }
      }
      if (LinkBlock.isLink(note.contentJson)) {
        final block = LinkBlock.decode(note.contentJson);
        for (final link in block.outgoingLinks) {
          if (link.targetNoteId == currentNote.id || link.targetNoteId == 0) {
            results.add(NoteWithLink(
              note: note,
              matchType: link.label ?? 'enlace',
              description: link.description,
            ));
          }
        }
      }
    }
    return results;
  }

  /// Busca menciones del título de la nota actual en otras notas.
  static List<NoteWithLink> findMentions(NoteModel currentNote, List<NoteModel> allNotes) {
    final results = <NoteWithLink>[];
    final titleWords = currentNote.title.toLowerCase().split(RegExp(r'\s+'));
    for (final note in allNotes) {
      if (note.id == currentNote.id) continue;
      if (titleWords.any((w) => w.length > 2 && note.title.toLowerCase().contains(w))) {
        results.add(NoteWithLink(note: note, matchType: 'mención textual'));
      }
    }
    return results;
  }

  Map<String, dynamic> toJson() => {
        marker: typeValue,
        'title': title,
        'outgoingLinks': outgoingLinks.map((l) => l.toJson()).toList(),
      };

  factory LinkBlock.fromJson(Map<String, dynamic> json) => LinkBlock(
        title: json['title'] as String? ?? 'Conexiones',
        outgoingLinks: (json['outgoingLinks'] as List?)
                ?.map((e) => LinkEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  String encode() => jsonEncode(toJson());

  static bool isLink(String contentJson) {
    try {
      return contentJson.trim().startsWith('{"$marker":"$typeValue"');
    } catch (_) {
      return false;
    }
  }

  factory LinkBlock.decode(String contentJson) {
    final data = jsonDecode(contentJson);
    return LinkBlock.fromJson(data as Map<String, dynamic>);
  }
}

class NoteWithLink {
  final NoteModel note;
  final String matchType;
  final String? description;

  NoteWithLink({
    required this.note,
    required this.matchType,
    this.description,
  });
}
