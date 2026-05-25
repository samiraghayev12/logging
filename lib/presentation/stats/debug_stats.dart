import 'package:flutter/material.dart';
import 'package:logging_service/presentation/detail/view/debug_detail.dart';
import 'package:logging_service/storage/debug_storage.dart';
import 'package:logging_service/utils/responsive_helper.dart';

class DebugStats extends StatelessWidget {
  const DebugStats({super.key});

  @override
  Widget build(BuildContext context) {
    final debug = DebugStorage();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (debug.requests.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            "Analytics",
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context, 22),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: ResponsiveHelper.getFontSize(context, 70),
                color: Colors.grey.withValues(alpha: 0.4),
              ),
              SizedBox(height: ResponsiveHelper.getSpacing(context, 16)),
              Text(
                'No data yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: ResponsiveHelper.getFontSize(context, 20),
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate statistics
    final totalRequests = debug.requests.length;
    final successfulRequests =
        debug.requests.where((r) => !r.hasError).length;
    final failedRequests = debug.requests.where((r) => r.hasError).length;
    final totalElapsedTime =
        debug.requests.fold<int>(0, (sum, r) => sum + (r.elapsedTime ?? 0));
    final avgElapsedTime = (totalElapsedTime / totalRequests).toInt();

    final sortedByTime = List.from(debug.requests)
      ..sort((a, b) => (b.elapsedTime ?? 0).compareTo(a.elapsedTime ?? 0));
    final slowestRequests = sortedByTime.take(3).toList();

    final sortedByTimeFastest = List.from(debug.requests)
      ..sort((a, b) => (a.elapsedTime ?? 0).compareTo(b.elapsedTime ?? 0));
    final fastestRequests = sortedByTimeFastest.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Analytics",
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, 22),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsGrid(context, isDark, totalRequests, successfulRequests,
                failedRequests, avgElapsedTime),
            SizedBox(height: ResponsiveHelper.getSpacing(context, 24)),
            _buildSectionTitle(context, "Slowest Requests"),
            SizedBox(height: ResponsiveHelper.getSpacing(context, 12)),
            _buildRequestsList(context, isDark, slowestRequests),
            SizedBox(height: ResponsiveHelper.getSpacing(context, 24)),
            _buildSectionTitle(context, "Fastest Requests"),
            SizedBox(height: ResponsiveHelper.getSpacing(context, 12)),
            _buildRequestsList(context, isDark, fastestRequests),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    bool isDark,
    int total,
    int successful,
    int failed,
    int avgTime,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: ResponsiveHelper.getSpacing(context, 12),
      crossAxisSpacing: ResponsiveHelper.getSpacing(context, 12),
      children: [
        _buildStatCard(
          context,
          isDark,
          title: "Total Requests",
          value: total.toString(),
          icon: Icons.list_rounded,
          color: Colors.blue,
        ),
        _buildStatCard(
          context,
          isDark,
          title: "Successful",
          value: successful.toString(),
          icon: Icons.check_circle_rounded,
          color: Colors.green,
        ),
        _buildStatCard(
          context,
          isDark,
          title: "Failed",
          value: failed.toString(),
          icon: Icons.error_rounded,
          color: Colors.red,
        ),
        _buildStatCard(
          context,
          isDark,
          title: "Avg Time",
          value: "${avgTime}ms",
          icon: Icons.speed_rounded,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: color,
            size: ResponsiveHelper.getFontSize(context, 26),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: ResponsiveHelper.getFontSize(context, 20),
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
              SizedBox(height: ResponsiveHelper.getSpacing(context, 4)),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: ResponsiveHelper.getFontSize(context, 13),
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: ResponsiveHelper.getFontSize(context, 16),
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    bool isDark,
    List requests,
  ) {
    return Column(
      children: List.generate(
        requests.length,
        (index) {
          final request = requests[index];
          return Padding(
            padding: EdgeInsets.only(bottom: ResponsiveHelper.getSpacing(context, 8)),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DebugDetail(debugModel: request),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[50],
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 12)),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.getPadding(context, 8), vertical: ResponsiveHelper.getPadding(context, 4)),
                      decoration: BoxDecoration(
                        color: request.httpMethodColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        request.httpMethod,
                        style: TextStyle(
                          color: request.httpMethodColor,
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getFontSize(context, 14),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getSpacing(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontSize: ResponsiveHelper.getFontSize(context, 14),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: ResponsiveHelper.getSpacing(context, 2)),
                          Text(
                            request.requestTime ?? "",
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    fontSize: ResponsiveHelper.getFontSize(context, 11),
                                    color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${request.elapsedTime} ms",
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontSize: ResponsiveHelper.getFontSize(context, 12),
                                fontWeight: FontWeight.w600,
                                color: request.elapsedTime! > 1000
                                    ? Colors.red
                                    : Colors.green,
                              ),
                        ),
                        SizedBox(height: ResponsiveHelper.getSpacing(context, 2)),
                        Text(
                          request.statusCode,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontSize: ResponsiveHelper.getFontSize(context, 11),
                                color: Colors.grey[500],
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
