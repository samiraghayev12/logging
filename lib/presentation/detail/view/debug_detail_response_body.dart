import 'package:flutter/material.dart';

import '../../../storage/debug_model.dart';
import '../../../utils/responsive_helper.dart';
import '../../widgets/debug_section.dart';

class DebugDetailResponseBody extends StatelessWidget {
  const DebugDetailResponseBody({super.key, required this.debugModel});

  final DebugModel debugModel;

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getPadding(context, 16);
    final gap = ResponsiveHelper.getSpacing(context, 20);
    final statusColor = debugModel.statusColor;
    final headers = debugModel.responseHeadersView();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        padding,
        padding,
        padding,
        padding + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        DebugSection(
          title: 'Status',
          children: [
            DebugCard(
              color: statusColor.withValues(alpha: 0.08),
              borderColor: statusColor.withValues(alpha: 0.3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    debugModel.isPending
                        ? Icons.hourglass_top_rounded
                        : (debugModel.isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded),
                    color: statusColor,
                    size: ResponsiveHelper.getFontSize(context, 22),
                  ),
                  SizedBox(width: ResponsiveHelper.getSpacing(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${debugModel.statusCode} · ${debugModel.statusLabel}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.getFontSize(context, 16),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getSpacing(context, 4)),
                        Text(
                          debugModel.statusMessage,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: ResponsiveHelper.getFontSize(context, 12),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        DebugSection(
          title: 'Response Body',
          children: [
            JsonBody(
              data: debugModel.responseData,
              emptyLabel: 'No response body',
            ),
          ],
        ),
        SizedBox(height: gap),
        DebugSection(
          title: 'Response Headers',
          trailingLabel: '${headers.length}',
          children: [HeaderList(headers: headers)],
        ),
      ],
    );
  }
}
