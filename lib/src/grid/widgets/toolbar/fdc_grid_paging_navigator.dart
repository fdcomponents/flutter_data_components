// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/fdc_app.dart';
import '../../../common/menu/fdc_menu.dart';
import '../../../data/fdc_data.dart';
import '../fdc_grid_items.dart';

/// Page navigation control for adapter-backed dataset paging.
///
/// Use [FdcGridPagingNavigator.input] for direct page entry or
/// [FdcGridPagingNavigator.numbered] for numbered page labels. Compose it
/// independently with [FdcGridPagingRecordInfo], [FdcGridPageSizeSelector],
/// [FdcGridSpacer], or other grid items in a toolbar or status bar.
class FdcGridPagingNavigator extends FdcGridItem {
  /// Creates a [FdcGridPagingNavigator].
  const FdcGridPagingNavigator.input({
    super.id,
    super.visible,
    super.placement = FdcGridItemPlacement.end,
    this.pageLabel,
    this.pageCountLabel,
    this.showFirstLastButtons = true,
    this.showPreviousNextButtons = true,
    this.allowPageInput = true,
  }) : _style = _FdcGridPageNavigatorStyle.input,

       /// Maximum number of numbered page buttons shown at once.
       visiblePageCount = 5,

       /// Shows first and last page boundaries around the numbered page window.
       showBoundaryPages = true;

  /// Creates a [FdcGridPagingNavigator].
  FdcGridPagingNavigator.numbered({
    super.id,
    super.visible,
    super.placement = FdcGridItemPlacement.end,
    this.visiblePageCount = 5,
    this.showBoundaryPages = true,
    this.showFirstLastButtons = false,
    this.showPreviousNextButtons = true,
  }) : _style = _FdcGridPageNavigatorStyle.numbered,

       /// Label shown before the current page value.
       pageLabel = '',

       /// Label used when presenting the total page count.
       pageCountLabel = '',

       /// Allows direct page-number entry.
       allowPageInput = false {
    if (visiblePageCount <= 0) {
      throw RangeError.value(
        visiblePageCount,
        'visiblePageCount',
        'Must be greater than zero.',
      );
    }
  }

  final _FdcGridPageNavigatorStyle _style;

  /// Label shown before the current page value.
  final String? pageLabel;

  /// Label used when presenting the total page count.
  final String? pageCountLabel;

  /// Shows buttons that jump directly to the first and last pages.
  final bool showFirstLastButtons;

  /// Shows buttons that move one page backward or forward.
  final bool showPreviousNextButtons;

  /// Allows direct page-number entry.
  final bool allowPageInput;

  /// Maximum number of numbered page buttons shown at once.
  final int visiblePageCount;

  /// Shows first and last page boundaries around the numbered page window.
  final bool showBoundaryPages;

  /// Builds this paging item for the current [dataSet] paging state.
  Widget buildForDataSet(BuildContext context, FdcDataSet dataSet) {
    final config = _style == _FdcGridPageNavigatorStyle.input
        ? _FdcGridPageNavigatorConfig.input(
            pageLabel: pageLabel ?? FdcApp.translationsOf(context).grid.page,
            pageCountLabel:
                pageCountLabel ?? FdcApp.translationsOf(context).grid.of,
            showFirstLastButtons: showFirstLastButtons,
            showPreviousNextButtons: showPreviousNextButtons,
            allowPageInput: allowPageInput,
          )
        : _FdcGridPageNavigatorConfig.numbered(
            visiblePageCount: visiblePageCount,
            showBoundaryPages: showBoundaryPages,
            showFirstLastButtons: showFirstLastButtons,
            showPreviousNextButtons: showPreviousNextButtons,
          );
    return _FdcGridPagingDataSetListener(
      dataSet: dataSet,
      builder: (context) => config.style == _FdcGridPageNavigatorStyle.numbered
          ? _FdcGridNumberedPageNavigatorView(dataSet: dataSet, config: config)
          : _FdcGridInputPageNavigatorView(dataSet: dataSet, config: config),
    );
  }
}

/// Displays the global record range of the currently loaded page.
class FdcGridPagingRecordInfo extends FdcGridItem {
  /// Creates a [FdcGridPagingRecordInfo].
  const FdcGridPagingRecordInfo({
    super.id,
    super.visible,
    super.placement = FdcGridItemPlacement.end,
    this.label = '',
    this.countLabel,
  });

  /// Display label shown to the user.
  final String label;

  /// Label used when presenting the current record count.
  final String? countLabel;

  /// Builds this paging item for the current [dataSet] paging state.
  Widget buildForDataSet(BuildContext context, FdcDataSet dataSet) {
    return _FdcGridPagingDataSetListener(
      dataSet: dataSet,
      builder: (context) => _FdcGridPagingRecordInfoView(
        dataSet: dataSet,
        config: FdcGridPagingRecordInfo(
          id: id,
          visible: visible,
          placement: placement,
          label: label,
          countLabel: countLabel ?? FdcApp.translationsOf(context).grid.of,
        ),
      ),
    );
  }
}

/// Selects the dataset page size while preserving the first visible global
/// record offset where possible.
class FdcGridPageSizeSelector extends FdcGridItem {
  /// Creates a [FdcGridPageSizeSelector].
  FdcGridPageSizeSelector({
    super.id,
    super.visible,
    super.placement = FdcGridItemPlacement.end,
    this.label = '',
    List<int> options = const <int>[100, 500, 1000, 5000, 10000],
  }) : options = List<int>.unmodifiable(options) {
    int? invalidOption;
    for (final option in this.options) {
      if (option <= 0) {
        invalidOption = option;
        break;
      }
    }
    if (invalidOption != null) {
      throw RangeError.value(
        invalidOption,
        'options',
        'Every page-size option must be greater than zero.',
      );
    }
    if (this.options.toSet().length != this.options.length) {
      throw ArgumentError.value(
        options,
        'options',
        'Page-size options must not contain duplicates.',
      );
    }
  }

  /// Display label shown to the user.
  final String label;

  /// Options used by this configuration.
  final List<int> options;

  /// Builds this paging item for the current [dataSet] paging state.
  Widget buildForDataSet(BuildContext context, FdcDataSet dataSet) {
    if (options.isEmpty) return const SizedBox.shrink();
    return _FdcGridPagingDataSetListener(
      dataSet: dataSet,
      builder: (context) =>
          _FdcGridPageSizeSelectorView(dataSet: dataSet, config: this),
    );
  }
}

class _FdcGridPagingDataSetListener extends StatefulWidget {
  const _FdcGridPagingDataSetListener({
    required this.dataSet,
    required this.builder,
  });

  final FdcDataSet dataSet;
  final WidgetBuilder builder;

  @override
  State<_FdcGridPagingDataSetListener> createState() =>
      _FdcGridPagingDataSetListenerState();
}

class _FdcGridPagingDataSetListenerState
    extends State<_FdcGridPagingDataSetListener> {
  @override
  void initState() {
    super.initState();
    widget.dataSet.addListener(_handleDataSetChanged);
  }

  @override
  void didUpdateWidget(covariant _FdcGridPagingDataSetListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.dataSet, widget.dataSet)) {
      oldWidget.dataSet.removeListener(_handleDataSetChanged);
      widget.dataSet.addListener(_handleDataSetChanged);
    }
  }

  @override
  void dispose() {
    widget.dataSet.removeListener(_handleDataSetChanged);
    super.dispose();
  }

  void _handleDataSetChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

enum _FdcGridPageNavigatorStyle { input, numbered }

class _FdcGridPageNavigatorConfig {
  const _FdcGridPageNavigatorConfig.input({
    required this.pageLabel,
    required this.pageCountLabel,
    required this.showFirstLastButtons,
    required this.showPreviousNextButtons,
    required this.allowPageInput,
  }) : style = _FdcGridPageNavigatorStyle.input,
       visiblePageCount = 5,
       showBoundaryPages = true;

  const _FdcGridPageNavigatorConfig.numbered({
    required this.visiblePageCount,
    required this.showBoundaryPages,
    required this.showFirstLastButtons,
    required this.showPreviousNextButtons,
  }) : style = _FdcGridPageNavigatorStyle.numbered,
       pageLabel = '',
       pageCountLabel = '',
       allowPageInput = false;

  final _FdcGridPageNavigatorStyle style;
  final String pageLabel;
  final String pageCountLabel;
  final bool showFirstLastButtons;
  final bool showPreviousNextButtons;
  final bool allowPageInput;
  final int visiblePageCount;
  final bool showBoundaryPages;
}

TextStyle _pagingTextStyle(BuildContext context) {
  final itemTheme = FdcGridItemTheme.maybeOf(context);
  return itemTheme == null
      ? Theme.of(context).textTheme.bodySmall ??
            DefaultTextStyle.of(context).style
      : itemTheme.textStyle.copyWith(color: itemTheme.textColor);
}

bool _navigationEnabled(FdcDataSet dataSet) {
  return dataSet.isOpen && dataSet.paging.enabled && !dataSet.work.isWorking;
}

Widget _pagingNavButton({
  required IconData icon,
  required String tooltip,
  required bool enabled,
  required bool canRun,
  required Future<void> Function() action,
}) {
  return IconButton(
    tooltip: tooltip,
    icon: Icon(icon, size: 17),
    visualDensity: VisualDensity.compact,
    splashRadius: 15,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 30, height: 30),
    mouseCursor: enabled && canRun
        ? SystemMouseCursors.click
        : SystemMouseCursors.basic,
    onPressed: enabled && canRun
        ? () {
            unawaited(action());
          }
        : null,
  );
}

class _FdcGridInputPageNavigatorView extends StatefulWidget {
  const _FdcGridInputPageNavigatorView({
    required this.dataSet,
    required this.config,
  });

  final FdcDataSet dataSet;
  final _FdcGridPageNavigatorConfig config;

  @override
  State<_FdcGridInputPageNavigatorView> createState() =>
      _FdcGridInputPageNavigatorViewState();
}

class _FdcGridInputPageNavigatorViewState
    extends State<_FdcGridInputPageNavigatorView> {
  late final TextEditingController _pageController;
  late final FocusNode _pageFocusNode;
  bool _editingPage = false;
  bool _submittingPage = false;

  @override
  void initState() {
    super.initState();
    _pageController = TextEditingController();
    _pageFocusNode = FocusNode()..addListener(_handleFocusChanged);
    widget.dataSet.addListener(_handleDataSetChanged);
  }

  @override
  void didUpdateWidget(covariant _FdcGridInputPageNavigatorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.dataSet, widget.dataSet)) {
      oldWidget.dataSet.removeListener(_handleDataSetChanged);
      widget.dataSet.addListener(_handleDataSetChanged);
      _cancelPageEdit(notify: false);
    }
  }

  @override
  void dispose() {
    widget.dataSet.removeListener(_handleDataSetChanged);
    _pageFocusNode.removeListener(_handleFocusChanged);
    _pageController.dispose();
    _pageFocusNode.dispose();
    super.dispose();
  }

  void _handleDataSetChanged() {
    if (!mounted) {
      return;
    }
    if (_editingPage && !_submittingPage && widget.dataSet.work.isWorking) {
      _cancelPageEdit(notify: false);
    }
    setState(() {});
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _beginPageEdit() {
    if (!widget.config.allowPageInput ||
        _editingPage ||
        !_navigationEnabled(widget.dataSet)) {
      return;
    }
    _pageController.text = '${widget.dataSet.paging.pageIndex + 1}';
    setState(() => _editingPage = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_editingPage) {
        return;
      }
      _pageFocusNode.requestFocus();
      _pageController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _pageController.text.length,
      );
    });
  }

  void _cancelPageEdit({bool notify = true}) {
    if (!_editingPage || _submittingPage) {
      return;
    }
    _editingPage = false;
    _pageFocusNode.unfocus();
    if (notify && mounted) {
      setState(() {});
    }
  }

  void _finishPageEdit() {
    if (!mounted) {
      return;
    }
    _pageController.text = '${widget.dataSet.paging.pageIndex + 1}';
    _submittingPage = false;
    _editingPage = false;
    _pageFocusNode.unfocus();
    setState(() {});
  }

  Future<void> _submitPageEdit() async {
    if (!_editingPage || _submittingPage) {
      return;
    }
    final requestedPage = int.tryParse(_pageController.text.trim());
    final pageCount = widget.dataSet.paging.pageCount;
    if (requestedPage == null || requestedPage < 1) {
      _cancelPageEdit();
      return;
    }

    setState(() => _submittingPage = true);
    try {
      if (pageCount != null && pageCount > 0 && requestedPage >= pageCount) {
        if (widget.dataSet.paging.pageIndex != pageCount - 1) {
          await widget.dataSet.paging.lastPage();
        }
      } else {
        final targetIndex = requestedPage - 1;
        if (targetIndex != widget.dataSet.paging.pageIndex) {
          await widget.dataSet.paging.openPage(targetIndex);
        }
      }
    } finally {
      _finishPageEdit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataSet = widget.dataSet;
    final config = widget.config;
    final textStyle = _pagingTextStyle(context);
    final enabled = _navigationEnabled(dataSet);
    final pageCount = dataSet.paging.pageCount;
    final currentPage = dataSet.paging.pageIndex + 1;
    const gap = 4.0;
    final pageBorderColor = _editingPage && _pageFocusNode.hasFocus
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).dividerColor;

    final pageInput = SizedBox(
      width: 48,
      height: 24,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          border: Border.all(color: pageBorderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: _editingPage
            ? Focus(
                onKeyEvent: (_, event) {
                  if (!_submittingPage &&
                      event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.escape) {
                    _cancelPageEdit();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Align(
                    child: SizedBox(
                      width: double.infinity,
                      child: TextField(
                        controller: _pageController,
                        focusNode: _pageFocusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          if (pageCount != null && pageCount > 0)
                            LengthLimitingTextInputFormatter(
                              pageCount.toString().length,
                            ),
                        ],
                        readOnly: _submittingPage,
                        textAlign: TextAlign.center,
                        style: textStyle,
                        cursorColor: Theme.of(context).colorScheme.primary,
                        decoration: null,
                        onSubmitted: (_) => _submitPageEdit(),
                        onTapOutside: (_) {
                          if (!_submittingPage) {
                            _cancelPageEdit();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              )
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  mouseCursor: enabled && config.allowPageInput
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  onTap: enabled && config.allowPageInput
                      ? _beginPageEdit
                      : null,
                  borderRadius: BorderRadius.circular(4),
                  child: Center(child: Text('$currentPage', style: textStyle)),
                ),
              ),
      ),
    );

    final pageInfo = SizedBox(
      height: 30,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (config.pageLabel.isNotEmpty) ...<Widget>[
            Text(config.pageLabel, style: textStyle),
            const SizedBox(width: 5),
          ],
          pageInput,
          if (pageCount != null) ...<Widget>[
            const SizedBox(width: 5),
            if (config.pageCountLabel.isNotEmpty) ...<Widget>[
              Text(config.pageCountLabel, style: textStyle),
              const SizedBox(width: 4),
            ],
            Text('$pageCount', style: textStyle),
          ],
        ],
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (config.showFirstLastButtons)
          _pagingNavButton(
            icon: Icons.first_page,
            tooltip: FdcApp.translationsOf(context).grid.firstPage,
            enabled: enabled,
            canRun: dataSet.paging.hasPriorPage,
            action: dataSet.paging.firstPage,
          ),
        if (config.showPreviousNextButtons)
          _pagingNavButton(
            icon: Icons.chevron_left,
            tooltip: FdcApp.translationsOf(context).grid.previousPage,
            enabled: enabled,
            canRun: dataSet.paging.hasPriorPage,
            action: dataSet.paging.priorPage,
          ),
        const SizedBox(width: gap),
        pageInfo,
        const SizedBox(width: gap),
        if (config.showPreviousNextButtons)
          _pagingNavButton(
            icon: Icons.chevron_right,
            tooltip: FdcApp.translationsOf(context).grid.nextPage,
            enabled: enabled,
            canRun: dataSet.paging.hasNextPage,
            action: dataSet.paging.nextPage,
          ),
        if (config.showFirstLastButtons)
          _pagingNavButton(
            icon: Icons.last_page,
            tooltip: FdcApp.translationsOf(context).grid.lastPage,
            enabled: enabled,
            canRun: pageCount != null && dataSet.paging.hasNextPage,
            action: dataSet.paging.lastPage,
          ),
      ],
    );
  }
}

class _FdcGridNumberedPageNavigatorView extends StatefulWidget {
  const _FdcGridNumberedPageNavigatorView({
    required this.dataSet,
    required this.config,
  });

  final FdcDataSet dataSet;
  final _FdcGridPageNavigatorConfig config;

  @override
  State<_FdcGridNumberedPageNavigatorView> createState() =>
      _FdcGridNumberedPageNavigatorViewState();
}

class _FdcGridNumberedPageNavigatorViewState
    extends State<_FdcGridNumberedPageNavigatorView> {
  int? _optimisticPage;
  int _navigationGeneration = 0;

  Future<void> _goToPage(int page) async {
    final generation = ++_navigationGeneration;
    setState(() => _optimisticPage = page);

    try {
      final dataSet = widget.dataSet;
      final pageCount = dataSet.paging.pageCount;
      if (page <= 1) {
        await dataSet.paging.firstPage();
      } else if (pageCount != null && page >= pageCount) {
        await dataSet.paging.lastPage();
      } else if (page - 1 != dataSet.paging.pageIndex) {
        await dataSet.paging.openPage(page - 1);
      }
    } finally {
      if (mounted && generation == _navigationGeneration) {
        setState(() => _optimisticPage = null);
      }
    }
  }

  List<int?> _pageTokens(int currentPage, int pageCount) {
    final visibleCount = widget.config.visiblePageCount < 1
        ? 1
        : widget.config.visiblePageCount;
    if (!widget.config.showBoundaryPages) {
      var start = currentPage - visibleCount ~/ 2;
      var end = start + visibleCount - 1;
      if (start < 1) {
        start = 1;
        end = visibleCount < pageCount ? visibleCount : pageCount;
      }
      if (end > pageCount) {
        end = pageCount;
        start = pageCount - visibleCount + 1;
        if (start < 1) start = 1;
      }
      return <int?>[for (var page = start; page <= end; page++) page];
    }

    if (pageCount <= visibleCount + 2) {
      return <int?>[for (var page = 1; page <= pageCount; page++) page];
    }

    var start = currentPage - visibleCount ~/ 2;
    var end = start + visibleCount - 1;
    if (start < 2) {
      start = 2;
      end = start + visibleCount - 1;
    }
    if (end > pageCount - 1) {
      end = pageCount - 1;
      start = end - visibleCount + 1;
      if (start < 2) start = 2;
    }

    return <int?>[
      1,
      if (start > 2) null,
      for (var page = start; page <= end; page++) page,
      if (end < pageCount - 1) null,
      pageCount,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final dataSet = widget.dataSet;
    final config = widget.config;
    final enabled = _navigationEnabled(dataSet);
    final currentPage = _optimisticPage ?? dataSet.paging.pageIndex + 1;
    final pageCount = dataSet.paging.pageCount;
    final textStyle = _pagingTextStyle(context);
    final tokens = pageCount == null
        ? <int?>[currentPage]
        : _pageTokens(currentPage, pageCount);
    const pageHeight = 28.0;
    const gap = 4.0;

    Widget pageLabel(int page) {
      final selected = page == currentPage;
      final colorScheme = Theme.of(context).colorScheme;
      final selectedStyle = textStyle.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      );

      return SizedBox(
        key: ValueKey<String>('fdc-paging-page-$page'),
        height: pageHeight,
        child: Material(
          color: selected ? Theme.of(context).hoverColor : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          child: InkWell(
            mouseCursor: enabled && !selected
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onTap: enabled && !selected
                ? () {
                    unawaited(_goToPage(page));
                  }
                : null,
            borderRadius: BorderRadius.circular(3),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Center(
                child: Text(
                  '$page',
                  style: selected ? selectedStyle : textStyle,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (config.showFirstLastButtons)
          _pagingNavButton(
            icon: Icons.first_page,
            tooltip: FdcApp.translationsOf(context).grid.firstPage,
            enabled: enabled,
            canRun: dataSet.paging.hasPriorPage,
            action: dataSet.paging.firstPage,
          ),
        if (config.showPreviousNextButtons)
          _pagingNavButton(
            icon: Icons.chevron_left,
            tooltip: FdcApp.translationsOf(context).grid.previousPage,
            enabled: enabled,
            canRun: dataSet.paging.hasPriorPage,
            action: dataSet.paging.priorPage,
          ),
        const SizedBox(width: gap),
        for (var index = 0; index < tokens.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(width: gap),
          if (tokens[index] == null)
            SizedBox(
              height: pageHeight,
              width: 18,
              child: Center(child: Text('…', style: textStyle)),
            )
          else
            pageLabel(tokens[index]!),
        ],
        const SizedBox(width: gap),
        if (config.showPreviousNextButtons)
          _pagingNavButton(
            icon: Icons.chevron_right,
            tooltip: FdcApp.translationsOf(context).grid.nextPage,
            enabled: enabled,
            canRun: dataSet.paging.hasNextPage,
            action: dataSet.paging.nextPage,
          ),
        if (config.showFirstLastButtons)
          _pagingNavButton(
            icon: Icons.last_page,
            tooltip: FdcApp.translationsOf(context).grid.lastPage,
            enabled: enabled,
            canRun: pageCount != null && dataSet.paging.hasNextPage,
            action: dataSet.paging.lastPage,
          ),
      ],
    );
  }
}

class _FdcGridPagingRecordInfoView extends StatelessWidget {
  const _FdcGridPagingRecordInfoView({
    required this.dataSet,
    required this.config,
  });

  final FdcDataSet dataSet;
  final FdcGridPagingRecordInfo config;

  @override
  Widget build(BuildContext context) {
    final textStyle = _pagingTextStyle(context);
    final total = dataSet.paging.totalRecordCount;
    final countLabel =
        config.countLabel ?? FdcApp.translationsOf(context).grid.of;
    final from = dataSet.paging.pageRecordCount == 0
        ? 0
        : dataSet.paging.pageOffset + 1;
    final to = dataSet.paging.pageOffset + dataSet.paging.pageRecordCount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (config.label.isNotEmpty) ...<Widget>[
          Text(config.label, style: textStyle),
          const SizedBox(width: 5),
        ],
        Text('$from–$to', style: textStyle),
        if (total != null) ...<Widget>[
          const SizedBox(width: 4),
          if (countLabel.isNotEmpty) ...<Widget>[
            Text(countLabel, style: textStyle),
            const SizedBox(width: 4),
          ],
          Text('$total', style: textStyle),
        ],
      ],
    );
  }
}

class _FdcGridPageSizeSelectorView extends StatelessWidget {
  const _FdcGridPageSizeSelectorView({
    required this.dataSet,
    required this.config,
  });

  final FdcDataSet dataSet;
  final FdcGridPageSizeSelector config;

  Future<void> _changePageSize(int pageSize) async {
    if (pageSize == dataSet.paging.pageSize) {
      return;
    }
    final targetPageIndex = dataSet.paging.pageOffset ~/ pageSize;
    await dataSet.paging.openPage(targetPageIndex, pageSize: pageSize);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = _pagingTextStyle(context);
    final enabled = _navigationEnabled(dataSet);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (config.label.isNotEmpty) ...<Widget>[
          Text(config.label, style: textStyle),
          const SizedBox(width: 5),
        ],
        FdcMenuAnchor(
          openOnTap: true,
          openOnSecondaryTap: false,
          consumeSecondaryTap: false,
          canOpen: () => enabled && config.options.isNotEmpty,
          entries: <FdcMenuEntry>[
            for (final size in config.options)
              FdcMenuCheckAction(
                text: '$size',
                checked: size == dataSet.paging.pageSize,
                enabled: enabled,
                onPressed: () {
                  unawaited(_changePageSize(size));
                },
              ),
          ],
          child: MouseRegion(
            cursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('${dataSet.paging.pageSize}', style: textStyle),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: enabled
                        ? textStyle.color
                        : Theme.of(context).disabledColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
