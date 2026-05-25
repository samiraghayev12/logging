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
  @override
  void initState() {
    HapticFeedback.lightImpact();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final debug = DebugStorage();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Responsive sizes
    final titleFontSize = ResponsiveHelper.getFontSize(context, 22);
    final iconSize = ResponsiveHelper.getFontSize(context, 24);
    final methodFontSize = ResponsiveHelper.getFontSize(context, 14);
    final statusFontSize = ResponsiveHelper.getFontSize(context, 14);
    final timestampFontSize = ResponsiveHelper.getFontSize(context, 13);
    final timeFontSize = ResponsiveHelper.getFontSize(context, 13);

    final paddingAll = ResponsiveHelper.getPadding(context, 12);
    final paddingLarge = ResponsiveHelper.getPadding(context, 16);
    final spacing = ResponsiveHelper.getSpacing(context, 12);
    final smallSpacing = ResponsiveHelper.getSpacing(context, 8);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
        title: Text(
          "Network Logs",
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, 22),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DebugStats()),
              );
            },
          ),
        ],
      ),
      body: debug.requests.isEmpty
          ? Center(
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
            )
          : Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 16)),
              child: ListView.builder(
                itemBuilder: (_, index) {
                  final request = debug.requests[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: ResponsiveHelper.getSpacing(context, 12)),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DebugDetail(
                              debugModel: request,
                            ),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.grey[50],
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[200]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: ResponsiveHelper.getFontSize(context, 32),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveHelper.getPadding(context, 8),
                                      vertical: ResponsiveHelper.getPadding(context, 4),
                                    ),
                                    decoration: BoxDecoration(
                                      color: request.httpMethodColor
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        request.httpMethod,
                                        style: TextStyle(
                                          color: request.httpMethodColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: ResponsiveHelper.getFontSize(context, 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveHelper.getSpacing(context, 12)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          request.path,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize: ResponsiveHelper.getFontSize(context, 15),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        SizedBox(height: ResponsiveHelper.getSpacing(context, 6)),
                                        Text(
                                          request.requestTimeString,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontSize: ResponsiveHelper.getFontSize(context, 13),
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveHelper.getSpacing(context, 12)),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: ResponsiveHelper.getPadding(context, 8),
                                          vertical: ResponsiveHelper.getPadding(context, 4),
                                        ),
                                        decoration: BoxDecoration(
                                          color: request.hasError
                                              ? Colors.red
                                                  .withValues(alpha: 0.1)
                                              : Colors.green
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 4,
                                              backgroundColor: request.hasError
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                            SizedBox(width: ResponsiveHelper.getSpacing(context, 6)),
                                            Text(
                                              request.hasError
                                                  ? "Error"
                                                  : "Success",
                                              style: TextStyle(
                                                color: request.hasError
                                                    ? Colors.red
                                                    : Colors.green,
                                                fontWeight: FontWeight.w600,
                                                fontSize: ResponsiveHelper.getFontSize(context, 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: ResponsiveHelper.getSpacing(context, 6)),
                                      Text(
                                        "${request.elapsedTime} ms",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontSize: ResponsiveHelper.getFontSize(context, 13),
                                              color: Colors.grey[500],
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                itemCount: debug.requests.length,
              ),
            ),
    );
  }
}
