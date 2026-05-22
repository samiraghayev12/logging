import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logging_service/presentation/detail/view/debug_detail.dart';
import 'package:logging_service/presentation/stats/debug_stats.dart';
import 'package:logging_service/storage/debug_storage.dart';

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
            fontSize: 22.sp,
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
                    size: 70.sp,
                    color: Colors.grey.withValues(alpha: 0.4),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No network calls yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 20.sp,
                          color: Colors.grey.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView.builder(
                itemBuilder: (_, index) {
                  final request = debug.requests[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
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
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.all(12.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 32.h,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: request.httpMethodColor
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Center(
                                      child: Text(
                                        request.httpMethod,
                                        style: TextStyle(
                                          color: request.httpMethodColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          request.path,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          request.requestTimeString,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontSize: 12.sp,
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: request.hasError
                                              ? Colors.red
                                                  .withValues(alpha: 0.1)
                                              : Colors.green
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6.r),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 4.r,
                                              backgroundColor: request.hasError
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                            SizedBox(width: 6.w),
                                            Text(
                                              request.hasError
                                                  ? "Error"
                                                  : "Success",
                                              style: TextStyle(
                                                color: request.hasError
                                                    ? Colors.red
                                                    : Colors.green,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      Text(
                                        "${request.elapsedTime} ms",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontSize: 12.sp,
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
