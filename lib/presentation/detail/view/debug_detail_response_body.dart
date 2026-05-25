import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_view/json_view.dart';
import 'package:logging_service/storage/debug_model.dart';
import 'package:logging_service/utils/responsive_helper.dart';

class DebugDetailResponseBody extends StatelessWidget {
  final DebugModel debugModel;

  const DebugDetailResponseBody({super.key, required this.debugModel});

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
    final isError = debugModel.response == null;
    final isSuccess = !isError && debugModel.statusCode.startsWith("2");
    final statusColor = isError || !isSuccess ? Colors.red : Colors.green;

    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            context,
            title: "Status Code",
            isDark: isDark,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 12)),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                      color: statusColor,
                      size: ResponsiveHelper.getFontSize(context, 24),
                    ),
                    SizedBox(width: ResponsiveHelper.getSpacing(context, 12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debugModel.statusCode,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.getFontSize(context, 18),
                          ),
                        ),
                        if (debugModel.statusMessage.isNotEmpty) ...[
                          SizedBox(height: ResponsiveHelper.getSpacing(context, 4)),
                          Text(
                            debugModel.statusMessage,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: ResponsiveHelper.getFontSize(context, 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (debugModel.responseData != null) ...[
            SizedBox(height: ResponsiveHelper.getSpacing(context, 20)),
            _buildSection(
              context,
              title: "Response Body",
              isDark: isDark,
              actionButton: debugModel.responseData is! FormData
                  ? IconButton(
                      icon: Icon(Icons.copy_rounded, size: ResponsiveHelper.getFontSize(context, 20)),
                      onPressed: () => _copyToClipboard(
                        context,
                        debugModel.responseData.toString(),
                        "Response",
                      ),
                      tooltip: "Copy Response",
                    )
                  : null,
              children: [
                if (debugModel.responseData is FormData)
                  Container(
                    padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 12)),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_rounded,
                          color: Colors.orange[700],
                          size: ResponsiveHelper.getFontSize(context, 20),
                        ),
                        SizedBox(width: ResponsiveHelper.getSpacing(context, 8)),
                        Text(
                          "Form Data is not supported yet",
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: ResponsiveHelper.getFontSize(context, 13),
                          ),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 12)),
                    child: JsonView(
                      shrinkWrap: true,
                      json: debugModel.responseData,
                    ),
                  ),
              ],
            ),
          ],
          if (debugModel.responseHeaders.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getSpacing(context, 20)),
            _buildSection(
              context,
              title: "Response Headers",
              isDark: isDark,
              children: [
                Column(
                  children: List.generate(
                    debugModel.responseHeaders.length,
                    (index) {
                      final entries = debugModel.responseHeaders.entries.toList();
                      final entry = entries[index];
                      final isLast = index == debugModel.responseHeaders.length - 1;

                      return Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 12)),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[900] : Colors.grey[50],
                              border: Border.all(
                                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                              ),
                              borderRadius: BorderRadius.circular(8),
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
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: ResponsiveHelper.getFontSize(context, 13),
                                            ),
                                      ),
                                      SizedBox(height: ResponsiveHelper.getSpacing(context, 6)),
                                      Text(
                                        entry.value.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(fontSize: ResponsiveHelper.getFontSize(context, 13)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.copy_rounded, size: ResponsiveHelper.getFontSize(context, 20)),
                                  onPressed: () => _copyToClipboard(
                                    context,
                                    entry.value.toString(),
                                    entry.key,
                                  ),
                                  tooltip: "Copy ${entry.key}",
                                ),
                              ],
                            ),
                          ),
                          if (!isLast) SizedBox(height: ResponsiveHelper.getSpacing(context, 8)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
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
                    fontSize: ResponsiveHelper.getFontSize(context, 16),
                  ),
            ),
            if (actionButton != null) actionButton,
          ],
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context, 8)),
        ...children,
      ],
    );
  }
}
