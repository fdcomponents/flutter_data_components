// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

/// Internal commit marker used when an event listener deliberately cancels a
/// value change. It stops the commit without being presented as a validation
/// or runtime error.
const String fdcEditorCommitCanceled = '\u0000fdc-editor-commit-canceled';

bool fdcIsEditorCommitCanceled(String? value) =>
    value == fdcEditorCommitCanceled;
