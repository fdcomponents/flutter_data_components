import 'package:flutter_data_components/src/editors/core/fdc_editor_text_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('text session builds collapsed controller values', () {
    final value = FdcEditorTextSession.collapsedValue('Alpha');

    expect(value.text, 'Alpha');
    expect(value.selection.baseOffset, 5);
    expect(value.selection.extentOffset, 5);
  });

  test('text session identifies revertable local edits', () {
    expect(
      FdcEditorTextSession.hasLocalEditToRevert(
        dirty: false,
        localErrorText: null,
        controllerText: 'Alpha',
        baselineText: 'Alpha',
      ),
      isFalse,
    );
    expect(
      FdcEditorTextSession.hasLocalEditToRevert(
        dirty: false,
        localErrorText: null,
        controllerText: 'Beta',
        baselineText: 'Alpha',
      ),
      isTrue,
    );
    expect(
      FdcEditorTextSession.hasLocalEditToRevert(
        dirty: false,
        localErrorText: 'Invalid',
        controllerText: 'Alpha',
        baselineText: 'Alpha',
      ),
      isTrue,
    );
  });

  test('text session identifies clean commit state', () {
    expect(
      FdcEditorTextSession.isCleanForCommit(
        dirty: false,
        localErrorText: null,
        localErrorBlocksCommit: false,
      ),
      isTrue,
    );
    expect(
      FdcEditorTextSession.isCleanForCommit(
        dirty: false,
        localErrorText: 'Warning',
        localErrorBlocksCommit: false,
      ),
      isTrue,
    );
    expect(
      FdcEditorTextSession.isCleanForCommit(
        dirty: false,
        localErrorText: 'Invalid',
        localErrorBlocksCommit: true,
      ),
      isFalse,
    );
  });
}
