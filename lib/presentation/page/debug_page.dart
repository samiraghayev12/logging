import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging_service/presentation/detail/view/debug_detail.dart';
import 'package:logging_service/presentation/stats/debug_stats.dart';
import 'package:logging_service/storage/debug_storage.dart';
import 'package:logging_service/utils/responsive_helper.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  late final DebugStorage debug;
  final Set<int> selectedIndexes = {};
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
    debug = DebugStorage();
  }

  @override
  void dispose() {
    selectedIndexes.clear();
    super.dispose();
  }

  bool get _isAllSelected =>
      debug.requests.isNotEmpty &&
          selectedIndexes.length == debug.requests.length;

  void _exitSelectionMode() {
    setState(() {
      isSelectionMode = false;
      selectedIndexes.clear();
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (!selectedIndexes.remove(index)) {
        selectedIndexes.add(index);
      }
    });
  }

  void _deleteSelected() {
    debug.deleteMultiple(selectedIndexes.toList());
    _exitSelectionMode();
  }

  void _deleteItem(int index) {
    debug.deleteAt(index);
    setState(() {
      final updated = <int>{};
      for (final i in selectedIndexes) {
        if (i == index) continue;
        updated.add(i > index ? i - 1 : i);
      }
      selectedIndexes
        ..clear()
        ..addAll(updated);
    });
  }

  void _selectAll() {
    setState(() {
      if (_isAllSelected) {
        selectedIndexes.clear();
      } else {
        selectedIndexes
          ..clear()
          ..addAll(List.generate(debug.requests.length, (i) => i));
      }
    });
  }

  void _openDetail(dynamic request) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DebugDetail(debugModel: request)),
    );
  }

  void _openStats() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DebugStats()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEmpty = debug.requests.isEmpty;

    return Scaffold(
      appBar: _buildAppBar(context, isEmpty: isEmpty),
      body: isEmpty
          ? _EmptyState()
          : Padding(
        padding:
        EdgeInsets.all(ResponsiveHelper.getPadding(context, 16)),
        child: ListView.builder(
          itemCount: debug.requests.length,
          itemBuilder: (_, index) {
            final request = debug.requests[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveHelper.getSpacing(context, 12),
              ),
              child: _RequestTile(
                request: request,
                index: index,
                isDark: isDark,
                isSelected: selectedIndexes.contains(index),
                isSelectionMode: isSelectionMode,
                onDismissed: () => _deleteItem(index),
                onToggle: () => _toggleSelection(index),
                onOpenDetail: () => _openDetail(request),
                onStartSelection: () {
                  setState(() => isSelectionMode = true);
                  _toggleSelection(index);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context,
      {required bool isEmpty}) {
    final titleStyle = TextStyle(
      fontSize: ResponsiveHelper.getFontSize(context, 22),
      fontWeight: FontWeight.w600,
    );

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        tooltip: 'Close',
        onPressed: () {
          if (isSelectionMode) {
            _exitSelectionMode();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(
        isSelectionMode
            ? '${selectedIndexes.length} selected'
            : 'Network Logs',
        style: titleStyle,
      ),
      actions: isSelectionMode
          ? [
        IconButton(
          icon: const Icon(Icons.done_all_rounded),
          tooltip: 'Select All',
          onPressed: _selectAll,
        ),
        IconButton(
          icon: const Icon(Icons.delete_rounded),
          tooltip: 'Delete Selected',
          onPressed:
          selectedIndexes.isEmpty ? null : _deleteSelected,
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cancel',
          onPressed: _exitSelectionMode,
        ),
      ]
          : [
        IconButton(
          icon: const Icon(Icons.select_all_rounded),
          tooltip: 'Select Multiple',
          onPressed: isEmpty
              ? null
              : () => setState(() => isSelectionMode = true),
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded),
          tooltip: 'Analytics',
          onPressed: _openStats,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: ResponsiveHelper.getFontSize(context, 70),
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context, 16)),
          Text(
            'No network calls yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: ResponsiveHelper.getFontSize(context, 20),
              color: Colors.grey.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final dynamic request;
  final int index;
  final bool isDark;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onDismissed;
  final VoidCallback onToggle;
  final VoidCallback onOpenDetail;
  final VoidCallback onStartSelection;

  const _RequestTile({
    required this.request,
    required this.index,
    required this.isDark,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onDismissed,
    required this.onToggle,
    required this.onOpenDetail,
    required this.onStartSelection,
  });

  @override
  Widget build(BuildContext context) {
    final padding16 = ResponsiveHelper.getPadding(context, 16);
    final padding8 = ResponsiveHelper.getPadding(context, 8);
    final padding4 = ResponsiveHelper.getPadding(context, 4);
    final spacing12 = ResponsiveHelper.getSpacing(context, 12);
    final spacing8 = ResponsiveHelper.getSpacing(context, 8);
    final spacing6 = ResponsiveHelper.getSpacing(context, 6);
    final font14 = ResponsiveHelper.getFontSize(context, 14);
    final font13 = ResponsiveHelper.getFontSize(context, 13);
    final font15 = ResponsiveHelper.getFontSize(context, 15);
    final font24 = ResponsiveHelper.getFontSize(context, 24);
    final font32 = ResponsiveHelper.getFontSize(context, 32);

    return Dismissible(
      key: Key('${request.id}-$index'),
      onDismissed: (_) => onDismissed(),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: padding16),
        child: Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: font24,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isSelectionMode) {
              onToggle();
            } else {
              onOpenDetail();
            }
          },
          onLongPress: () {
            if (isSelectionMode) {
              onToggle();
            } else {
              onStartSelection();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? Colors.blue[900] : Colors.blue[50])
                  : (isDark ? Colors.grey[900] : Colors.grey[50]),
              border: Border.all(
                color: isSelected
                    ? Colors.blue
                    : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(padding16),
            child: Row(
              children: [
                if (isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggle(),
                  ),
                  SizedBox(width: spacing8),
                ],
                Container(
                  height: font32,
                  padding: EdgeInsets.symmetric(
                    horizontal: padding8,
                    vertical: padding4,
                  ),
                  decoration: BoxDecoration(
                    color: request.httpMethodColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      request.httpMethod,
                      style: TextStyle(
                        color: request.httpMethodColor,
                        fontWeight: FontWeight.w700,
                        fontSize: font14,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.path,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          fontSize: font15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: spacing6),
                      Text(
                        request.requestTimeString,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                          fontSize: font13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing12),
                _StatusBadge(
                  hasError: request.hasError,
                  elapsedMs: request.elapsedTime,
                  padding8: padding8,
                  padding4: padding4,
                  spacing6: spacing6,
                  fontSize: font14,
                  smallFontSize: font13,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool hasError;
  final dynamic elapsedMs;
  final double padding8;
  final double padding4;
  final double spacing6;
  final double fontSize;
  final double smallFontSize;

  const _StatusBadge({
    required this.hasError,
    required this.elapsedMs,
    required this.padding8,
    required this.padding4,
    required this.spacing6,
    required this.fontSize,
    required this.smallFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final color = hasError ? Colors.red : Colors.green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: padding8,
            vertical: padding4,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 4, backgroundColor: color),
              SizedBox(width: spacing6),
              Text(
                hasError ? 'Error' : 'Success',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing6),
        Text(
          '$elapsedMs ms',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: smallFontSize,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}