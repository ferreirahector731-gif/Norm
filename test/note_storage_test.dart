import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nota_ia_app/core/database/database_service.dart';
import 'package:nota_ia_app/features/notes/domain/note_document_codec.dart';
import 'package:nota_ia_app/features/notes/domain/note_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('guarda y recupera notas en almacenamiento local web', () async {
    await DatabaseService.initialize();

    final note = NoteModel.create(
      title: 'Prueba local',
      contentJson: NoteDocumentCodec.encode(
        Document.blank(withInitialText: true),
      ),
    );

    await DatabaseService.saveNote(note);
    final notes = await DatabaseService.getAllNotes();

    expect(notes, isNotEmpty);
    expect(notes.first.title, 'Prueba local');
  });
}
