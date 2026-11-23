import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidslearn/drawing_archive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('save and reload normalized drawing strokes', () async {
    final drawing = SavedDrawing(id: 'drawing-1', createdAt: '2026-11-23T00:00:00Z',
      strokes: [[const Offset(.1,.2),const Offset(.8,.9)]]);
    await DrawingArchive.saveLocal(drawing);
    final loaded = await DrawingArchive.readLocal();
    expect(loaded.length, 1);
    expect(loaded.single.strokes.single.last, const Offset(.8,.9));
  });
  test('replace same ID and cap local archive at 20', () async {
    for(var i=0;i<25;i++) {
      await DrawingArchive.saveLocal(SavedDrawing(id:'id-$i',
        createdAt:'2026-11-23',strokes:[]));
    }
    expect((await DrawingArchive.readLocal()).length, 20);
    await DrawingArchive.saveLocal(const SavedDrawing(
      id:'id-24',createdAt:'new',strokes:[]));
    expect((await DrawingArchive.readLocal()).length, 20);
    expect((await DrawingArchive.readLocal()).first.createdAt, 'new');
  });
}
