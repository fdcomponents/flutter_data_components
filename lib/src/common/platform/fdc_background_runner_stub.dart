// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Runs [task] using the platform-specific background execution strategy.
Future<T> fdcRunInBackground<T>(T Function() task) async => task();
