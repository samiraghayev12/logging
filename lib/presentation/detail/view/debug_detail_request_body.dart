import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:json_view/json_view.dart';
import 'package:logging_service/storage/debug_model.dart';

class DebugDetailRequestBody extends StatelessWidget {
  final DebugModel debugModel;

  const DebugDetailRequestBody({super.key, required this.debugModel});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label copied"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            context,
            title: "URL",
            isDark: isDark,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[50],
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        debugModel.url,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      icon: Icon(Icons.copy_rounded, size: 20.sp),
                      onPressed: () => _copyToClipboard(context, debugModel.url, "URL"),
                      tooltip: "Copy URL",
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildSection(
            context,
            title: "HTTP Method",
            isDark: isDark,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: debugModel.httpMethodColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: debugModel.httpMethodColor.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  debugModel.httpMethod,
                  style: TextStyle(
                    color: debugModel.httpMethodColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildSection(
            context,
            title: "Request Body",
            isDark: isDark,
            actionButton: debugModel.requestData is! FormData
                ? IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () => _copyToClipboard(
                      context,
                      debugModel.requestData.toString(),
                      "Body",
                    ),
                    tooltip: "Copy Body",
                  )
                : null,
            children: [
              if (debugModel.requestData is FormData)
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        color: Colors.orange[700],
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Form Data is not supported yet",
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[50],
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.all(12.w),
                  child: JsonView(
                    shrinkWrap: true,
                    json: debugModel.requestData,
                  ),
                ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildSection(
            context,
            title: "HTTP Headers",
            isDark: isDark,
            children: [
              Column(
                children: List.generate(
                  debugModel.requestHeaders.length,
                  (index) {
                    final entries = debugModel.requestHeaders.entries.toList();
                    final entry = entries[index];
                    final isLast = index == debugModel.requestHeaders.length - 1;

                    return Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.grey[50],
                            border: Border.all(
                              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      entry.value,
                                      style: Theme.of(context).textTheme.bodySmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18.0),
                                onPressed: () => _copyToClipboard(
                                  context,
                                  entry.value,
                                  entry.key,
                                ),
                                tooltip: "Copy ${entry.key}",
                              ),
                            ],
                          ),
                        ),
                        if (!isLast) const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required bool isDark,
    required List<Widget> children,
    Widget? actionButton,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
            ),
            if (actionButton != null) actionButton,
          ],
        ),
        SizedBox(height: 8.h),
        ...children,
      ],
    );
  }
}
