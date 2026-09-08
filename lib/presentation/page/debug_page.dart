import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../storage/debug_model.dart';
import '../../storage/debug_storage.dart';
import '../../utils/log_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../detail/view/debug_detail.dart';
import '../stats/debug_stats.dart';

/// Loglar üçün status filtri.
enum DebugFilter { all, success, error, pending }

extension on DebugFilter {
  String get label {
    switch (this) {
      case DebugFilter.all:
        return 'All';
      case DebugFilter.success:
        return 'Success';
      case DebugFilter.error:
        return 'Errors';
      case DebugFilter.pending:
        return 'Pending';
    }
  }
}

/// Şəbəkə loglarının siyahısı.
///
/// `DebugStorage`-a özü qulaq asır — appda əlavə `ListenableBuilder` lazım deyil.
class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final DebugStorage debug = DebugStorage();
  final TextEditingController _searchController = TextEditingController();

  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;
  bool _isSearching = false;
  DebugFilter _filter = DebugFilter.all;

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DebugModel> get _visibleRequests {
    final query = _searchController.text;
    return debug.requests.where((request) {
      if (!request.matches(query)) return false;
      switch (_filter) {
        case DebugFilter.all:
          return true;
        case DebugFilter.success:
          return request.isSuccess;
        case DebugFilter.error:
          return request.hasError;
        case DebugFilter.pending:
          return request.isPending;
      }
    }).toList();
  }

  bool _isAllSelected(List<DebugModel> visible) =>
      visible.isNotEmpty && visible.every((r) => _selectedIds.contains(r.id));

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
      if (_selectedIds.isEmpty) _isSelectionMode = false;
    });
  }

  void _deleteSelected() {
    debug.deleteByIds(_selectedIds);
    _exitSelectionMode();
  }

  void _selectAll(List<DebugModel> visible) {
    setState(() {
      if (_isAllSelected(visible)) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds
          ..clear()
          ..addAll(visible.map((r) => r.id));
      }
    });
  }

  void _openDetail(DebugModel request) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DebugDetail(debugModel: request)),
    );
  }

  void _openStats() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DebugStats()),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) _searchController.clear();
    });
  }

  Future<void> _confirmClear() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all logs?'),
        content: Text('${debug.count} request(s) will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (shouldClear ?? false) {
      debug.clear();
      _exitSelectionMode();
    }
  }

  void _exportAll() {
    final payload = LogFormatter.pretty(debug.exportAll());
    Clipboard.setData(ClipboardData(text: payload));
    _showSnack('${debug.count} log(s) copied as JSON');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.clampTextScale(
      context,
      ListenableBuilder(
        listenable: debug,
        builder: (context, _) => _buildScaffold(context),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visible = _visibleRequests;
    final padding = ResponsiveHelper.getPadding(context, 16);

    // Silinmiş elementlər seçimdə qalmasın.
    _selectedIds.removeWhere((id) => debug.findById(id) == null);

    return Scaffold(
      appBar: _buildAppBar(context, visible),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _FilterBar(
              current: _filter,
              counts: {
                DebugFilter.all: debug.count,
                DebugFilter.success: debug.successCount,
                DebugFilter.error: debug.errorCount,
                DebugFilter.pending: debug.pendingCount,
              },
              onChanged: (value) => setState(() => _filter = value),
            ),
            if (!debug.isRecording) const _RecordingPausedBanner(),
            Expanded(
              child: visible.isEmpty
                  ? _EmptyState(
                      isFiltered: debug.requests.isNotEmpty,
                      onReset: () => setState(() {
                        _filter = DebugFilter.all;
                        _searchController.clear();
                        _isSearching = false;
                      }),
                    )
                  : ResponsiveHelper.constrain(
                      context,
                      ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          padding,
                          ResponsiveHelper.getSpacing(context, 4),
                          padding,
                          padding + MediaQuery.paddingOf(context).bottom,
                        ),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => SizedBox(
                          height: ResponsiveHelper.getSpacing(context, 10),
                        ),
                        itemBuilder: (_, index) {
                          final request = visible[index];
                          return _RequestTile(
                            request: request,
                            isDark: isDark,
                            isSelected: _selectedIds.contains(request.id),
                            isSelectionMode: _isSelectionMode,
                            onDismissed: () => debug.deleteById(request.id),
                            onToggle: () => _toggleSelection(request.id),
                            onOpenDetail: () => _openDetail(request),
                            onStartSelection: () {
                              setState(() => _isSelectionMode = true);
                              _toggleSelection(request.id);
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    List<DebugModel> visible,
  ) {
    final titleStyle = TextStyle(
      fontSize: ResponsiveHelper.getFontSize(context, 20),
      fontWeight: FontWeight.w600,
    );

    if (_isSelectionMode) {
      return AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cancel',
          onPressed: _exitSelectionMode,
        ),
        title: Text(
          '${_selectedIds.length} selected',
          style: titleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Select all',
            onPressed: visible.isEmpty ? null : () => _selectAll(visible),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            tooltip: 'Delete selected',
            onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
          ),
        ],
      );
    }

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: _isSearching ? 0 : null,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        tooltip: 'Close',
        onPressed: () {
          if (_isSearching) {
            _toggleSearch();
          } else {
            Navigator.of(context).maybePop();
          }
        },
      ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context, 16),
              ),
              decoration: InputDecoration(
                hintText: 'Search url, method, status…',
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(context, 15),
                ),
              ),
            )
          : Text(
              'Network Logs',
              style: titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.search_off_rounded : Icons.search_rounded),
          tooltip: _isSearching ? 'Close search' : 'Search',
          onPressed: _toggleSearch,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          tooltip: 'More',
          onSelected: (value) {
            switch (value) {
              case 'stats':
                _openStats();
              case 'select':
                setState(() => _isSelectionMode = true);
              case 'record':
                debug.setRecording(!debug.isRecording);
              case 'export':
                _exportAll();
              case 'clear':
                _confirmClear();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'stats',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.bar_chart_rounded),
                title: Text('Analytics'),
              ),
            ),
            PopupMenuItem(
              value: 'select',
              enabled: visible.isNotEmpty,
              child: const ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.checklist_rounded),
                title: Text('Select multiple'),
              ),
            ),
            PopupMenuItem(
              value: 'record',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  debug.isRecording
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_rounded,
                ),
                title: Text(debug.isRecording ? 'Pause recording' : 'Resume recording'),
              ),
            ),
            PopupMenuItem(
              value: 'export',
              enabled: debug.count > 0,
              child: const ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.ios_share_rounded),
                title: Text('Copy all as JSON'),
              ),
            ),
            PopupMenuItem(
              value: 'clear',
              enabled: debug.count > 0,
              child: const ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_sweep_rounded),
                title: Text('Clear all'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecordingPausedBanner extends StatelessWidget {
  const _RecordingPausedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.15),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getPadding(context, 16),
        vertical: ResponsiveHelper.getPadding(context, 8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.pause_circle_rounded,
            size: ResponsiveHelper.getFontSize(context, 18),
            color: Colors.orange.shade800,
          ),
          SizedBox(width: ResponsiveHelper.getSpacing(context, 8)),
          Expanded(
            child: Text(
              'Recording is paused — new requests are not logged',
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context, 12),
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.current,
    required this.counts,
    required this.onChanged,
  });

  final DebugFilter current;
  final Map<DebugFilter, int> counts;
  final ValueChanged<DebugFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveHelper.getSpacing(context, 8);

    return SizedBox(
      height: ResponsiveHelper.getUIElementSize(context, 48),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getPadding(context, 16),
        ),
        itemCount: DebugFilter.values.length,
        separatorBuilder: (_, __) => SizedBox(width: spacing),
        itemBuilder: (_, index) {
          final filter = DebugFilter.values[index];
          final count = counts[filter] ?? 0;
          return Center(
            child: ChoiceChip(
              selected: current == filter,
              onSelected: (_) => onChanged(filter),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Text(
                '${filter.label} ($count)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(context, 12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isFiltered, required this.onReset});

  final bool isFiltered;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered ? Icons.search_off_rounded : Icons.cloud_off_rounded,
              size: ResponsiveHelper.getFontSize(context, 64),
              color: Colors.grey.withValues(alpha: 0.4),
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context, 16)),
            Text(
              isFiltered ? 'No matching requests' : 'No network calls yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: ResponsiveHelper.getFontSize(context, 18),
                    color: Colors.grey.withValues(alpha: 0.7),
                  ),
            ),
            if (isFiltered) ...[
              SizedBox(height: ResponsiveHelper.getSpacing(context, 12)),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Reset filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.isDark,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onDismissed,
    required this.onToggle,
    required this.onOpenDetail,
    required this.onStartSelection,
  });

  final DebugModel request;
  final bool isDark;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onDismissed;
  final VoidCallback onToggle;
  final VoidCallback onOpenDetail;
  final VoidCallback onStartSelection;

  @override
  Widget build(BuildContext context) {
    final padding12 = ResponsiveHelper.getPadding(context, 12);
    final spacing10 = ResponsiveHelper.getSpacing(context, 10);
    final spacing4 = ResponsiveHelper.getSpacing(context, 4);
    final font11 = ResponsiveHelper.getFontSize(context, 11);
    final font12 = ResponsiveHelper.getFontSize(context, 12);
    final font14 = ResponsiveHelper.getFontSize(context, 14);

    return Dismissible(
      key: ValueKey<int>(request.id),
      direction: isSelectionMode
          ? DismissDirection.none
          : DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: padding12),
        child: Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: ResponsiveHelper.getFontSize(context, 22),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isSelectionMode ? onToggle : onOpenDetail,
          onLongPress: isSelectionMode ? onToggle : onStartSelection,
          child: Ink(
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
            padding: EdgeInsets.all(padding12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isSelectionMode) ...[
                  SizedBox(
                    width: ResponsiveHelper.getUIElementSize(context, 24),
                    height: ResponsiveHelper.getUIElementSize(context, 24),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggle(),
                    ),
                  ),
                  SizedBox(width: spacing10),
                ],
                _MethodBadge(request: request, fontSize: font11),
                SizedBox(width: spacing10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        request.shortPath,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: font14,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                      ),
                      SizedBox(height: spacing4),
                      Text(
                        '${request.startClockLabel} · ${request.host}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: font11,
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing10),
                _StatusBadge(request: request, fontSize: font12, smallFontSize: font11),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.request, required this.fontSize});

  final DebugModel request;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ResponsiveHelper.getUIElementSize(context, 58),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getPadding(context, 6),
        vertical: ResponsiveHelper.getPadding(context, 6),
      ),
      decoration: BoxDecoration(
        color: request.httpMethodColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          request.httpMethod,
          maxLines: 1,
          style: TextStyle(
            color: request.httpMethodColor,
            fontWeight: FontWeight.w700,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.request,
    required this.fontSize,
    required this.smallFontSize,
  });

  final DebugModel request;
  final double fontSize;
  final double smallFontSize;

  @override
  Widget build(BuildContext context) {
    final color = request.statusColor;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: ResponsiveHelper.getUIElementSize(context, 92),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getPadding(context, 8),
              vertical: ResponsiveHelper.getPadding(context, 4),
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (request.isPending)
                  SizedBox(
                    width: fontSize * 0.7,
                    height: fontSize * 0.7,
                    child: CircularProgressIndicator(strokeWidth: 1.6, color: color),
                  )
                else
                  Container(
                    width: fontSize * 0.55,
                    height: fontSize * 0.55,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                SizedBox(width: ResponsiveHelper.getSpacing(context, 5)),
                Flexible(
                  child: Text(
                    request.statusCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context, 4)),
          Text(
            request.elapsedTimeInMs,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: smallFontSize,
                  fontWeight: FontWeight.w600,
                  color: request.durationColor,
                ),
          ),
        ],
      ),
    );
  }
}
