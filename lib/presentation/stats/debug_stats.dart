import 'package:flutter/material.dart';

import '../../storage/debug_model.dart';
import '../../storage/debug_storage.dart';
import '../../utils/responsive_helper.dart';
import '../detail/view/debug_detail.dart';
import '../widgets/debug_section.dart';

class DebugStats extends StatelessWidget {
  const DebugStats({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.clampTextScale(
      context,
      ListenableBuilder(
        listenable: DebugStorage(),
        builder: (context, _) => _buildScaffold(context),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final debug = DebugStorage();
    final requests = debug.requests;
    final padding = ResponsiveHelper.getPadding(context, 16);

    final appBar = AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: false,
      title: Text(
        'Analytics',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: ResponsiveHelper.getFontSize(context, 20),
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (requests.isEmpty) {
      return Scaffold(
        appBar: appBar,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: ResponsiveHelper.getFontSize(context, 64),
                color: Colors.grey.withValues(alpha: 0.4),
              ),
              SizedBox(height: ResponsiveHelper.getSpacing(context, 16)),
              Text(
                'No data yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: ResponsiveHelper.getFontSize(context, 18),
                      color: Colors.grey.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final completed = requests.where((r) => r.elapsedTime != null).toList();
    final slowest = List<DebugModel>.from(completed)
      ..sort((a, b) => b.elapsedTime!.compareTo(a.elapsedTime!));
    final fastest = slowest.reversed.toList();

    final byMethod = <String, int>{};
    for (final request in requests) {
      byMethod[request.httpMethod] = (byMethod[request.httpMethod] ?? 0) + 1;
    }

    final errorRate = requests.isEmpty
        ? 0
        : (debug.errorCount / requests.length * 100).round();

    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        top: false,
        child: ResponsiveHelper.constrain(
          context,
          ListView(
            padding: EdgeInsets.fromLTRB(
              padding,
              padding,
              padding,
              padding + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              _StatsGrid(
                total: requests.length,
                successful: debug.successCount,
                failed: debug.errorCount,
                pending: debug.pendingCount,
                avgMs: debug.averageElapsedMs,
                errorRate: errorRate,
              ),
              SizedBox(height: ResponsiveHelper.getSpacing(context, 24)),
              DebugSection(
                title: 'Requests by Method',
                children: [
                  Wrap(
                    spacing: ResponsiveHelper.getSpacing(context, 8),
                    runSpacing: ResponsiveHelper.getSpacing(context, 8),
                    children: byMethod.entries
                        .map(
                          (entry) => InfoChip(
                            icon: Icons.http_rounded,
                            label: '${entry.key} · ${entry.value}',
                            color: _methodColor(entry.key),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              if (slowest.isNotEmpty) ...[
                SizedBox(height: ResponsiveHelper.getSpacing(context, 24)),
                DebugSection(
                  title: 'Slowest Requests',
                  children: [_RequestList(requests: slowest.take(5).toList())],
                ),
                SizedBox(height: ResponsiveHelper.getSpacing(context, 24)),
                DebugSection(
                  title: 'Fastest Requests',
                  children: [_RequestList(requests: fastest.take(5).toList())],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Color _methodColor(String method) {
    switch (method) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.orange;
      case 'PUT':
        return Colors.blueAccent;
      case 'PATCH':
        return Colors.purple;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.total,
    required this.successful,
    required this.failed,
    required this.pending,
    required this.avgMs,
    required this.errorRate,
  });

  final int total;
  final int successful;
  final int failed;
  final int pending;
  final int avgMs;
  final int errorRate;

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.gridColumns(context);
    final spacing = ResponsiveHelper.getSpacing(context, 12);

    final cards = <Widget>[
      _StatCard(
        title: 'Total',
        value: '$total',
        icon: Icons.list_rounded,
        color: Colors.blue,
      ),
      _StatCard(
        title: 'Successful',
        value: '$successful',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
      ),
      _StatCard(
        title: 'Failed',
        value: '$failed',
        icon: Icons.error_rounded,
        color: Colors.red,
      ),
      _StatCard(
        title: 'Pending',
        value: '$pending',
        icon: Icons.hourglass_top_rounded,
        color: Colors.blueGrey,
      ),
      _StatCard(
        title: 'Avg Time',
        value: '$avgMs ms',
        icon: Icons.speed_rounded,
        color: Colors.orange,
      ),
      _StatCard(
        title: 'Error Rate',
        value: '$errorRate%',
        icon: Icons.percent_rounded,
        color: errorRate > 20 ? Colors.red : Colors.teal,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: ResponsiveHelper.getFontSize(context, 22)),
          SizedBox(height: ResponsiveHelper.getSpacing(context, 10)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: ResponsiveHelper.getFontSize(context, 19),
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context, 2)),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: ResponsiveHelper.getFontSize(context, 11),
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({required this.requests});

  final List<DebugModel> requests;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < requests.length; i++) ...[
          _StatRequestTile(request: requests[i]),
          if (i != requests.length - 1)
            SizedBox(height: ResponsiveHelper.getSpacing(context, 8)),
        ],
      ],
    );
  }
}

class _StatRequestTile extends StatelessWidget {
  const _StatRequestTile({required this.request});

  final DebugModel request;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DebugDetail(debugModel: request),
          ),
        ),
        child: DebugCard(
          child: Row(
            children: [
              Container(
                width: ResponsiveHelper.getUIElementSize(context, 54),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getPadding(context, 6),
                  vertical: ResponsiveHelper.getPadding(context, 4),
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
                      fontSize: ResponsiveHelper.getFontSize(context, 11),
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getSpacing(context, 10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      request.shortPath,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: ResponsiveHelper.getFontSize(context, 13),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: ResponsiveHelper.getSpacing(context, 2)),
                    Text(
                      request.startClockLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: ResponsiveHelper.getFontSize(context, 10),
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getSpacing(context, 8)),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveHelper.getUIElementSize(context, 80),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      request.elapsedTimeInMs,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: ResponsiveHelper.getFontSize(context, 12),
                            fontWeight: FontWeight.w700,
                            color: request.durationColor,
                          ),
                    ),
                    SizedBox(height: ResponsiveHelper.getSpacing(context, 2)),
                    Text(
                      request.statusCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: ResponsiveHelper.getFontSize(context, 10),
                            color: request.statusColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
