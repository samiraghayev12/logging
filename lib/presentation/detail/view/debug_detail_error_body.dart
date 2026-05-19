import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging_service/storage/debug_model.dart';

class DebugDetailErrorBody extends StatelessWidget {
  final DebugModel debugModel;

  const DebugDetailErrorBody({super.key, required this.debugModel});

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            context,
            title: "Error Details",
            isDark: isDark,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_rounded,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debugModel.errorStatusCode,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          if (debugModel.statusMessage.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              debugModel.errorStatusMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (debugModel.errorHeaders.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSection(
              context,
              title: "Error Headers",
              isDark: isDark,
              children: [
                Column(
                  children: List.generate(
                    debugModel.errorHeaders.length,
                    (index) {
                      final entries = debugModel.errorHeaders.entries.toList();
                      final entry = entries[index];
                      final isLast = index == debugModel.errorHeaders.length - 1;

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
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
                                            ?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        entry.value.toString(),
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 18),
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
                          if (!isLast) const SizedBox(height: 8),
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
                  ),
            ),
            if (actionButton != null) actionButton,
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}
