import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_view/json_view.dart';
import 'package:logging_service/storage/debug_model.dart';
import 'package:logging_service/utils/responsive_helper.dart';

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
      padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            context,
            title: "URL",
            isDark: isDark,
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
                  children: [
                    Expanded(
                      child: Text(
                        debugModel.url,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: ResponsiveHelper.getFontSize(context, 14)),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getSpacing(context, 8)),
                    IconButton(
                      icon: Icon(Icons.copy_rounded, size: ResponsiveHelper.getFontSize(context, 18)),
                      onPressed: () =>
                          _copyToClipboard(context, debugModel.url, "URL"),
                      tooltip: "Copy URL",
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context, 20)),
          _buildSection(
            context,
            title: "HTTP Method",
            isDark: isDark,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getPadding(context, 12), vertical: ResponsiveHelper.getPadding(context, 8)),
                decoration: BoxDecoration(
                  color: debugModel.httpMethodColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: debugModel.httpMethodColor.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  debugModel.httpMethod,
                  style: TextStyle(
                    color: debugModel.httpMethodColor,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getFontSize(context, 14),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context, 20)),
          _buildSection(
            context,
            title: "Request Body",
            isDark: isDark,
            actionButton: debugModel.requestData is! FormData
                ? IconButton(
                    icon: Icon(Icons.copy_rounded, size: ResponsiveHelper.getFontSize(context, 20)),
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
                    styleScheme: JsonStyleScheme(
                      keysStyle: TextStyle(
                        color: isDark ? const Color(0xFF79C0FF) : const Color(0xFF0550AE),
                        fontSize: ResponsiveHelper.getFontSize(context, 13),
                        fontWeight: FontWeight.w600,
                      ),
                      valuesStyle: TextStyle(
                        color: isDark ? const Color(0xFF85E89D) : const Color(0xFF033A16),
                        fontSize: ResponsiveHelper.getFontSize(context, 13),
                      ),
                    ),
                    shrinkWrap: true,
                    json: debugModel.requestData,
                  ),
                ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context, 20)),
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
                    final isLast =
                        index == debugModel.requestHeaders.length - 1;

                    return Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 12)),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.grey[50],
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[200]!,
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
                                      entry.value,
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
                              SizedBox(width: ResponsiveHelper.getSpacing(context, 8)),
                              IconButton(
                                icon:
                                    const Icon(Icons.copy_rounded, size: 18.0),
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
                        if (!isLast) SizedBox(height: ResponsiveHelper.getSpacing(context, 8)),
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
