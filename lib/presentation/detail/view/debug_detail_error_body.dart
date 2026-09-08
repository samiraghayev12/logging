import 'package:flutter/material.dart';

import '../../../storage/debug_model.dart';
import '../../../utils/responsive_helper.dart';
import '../../widgets/debug_section.dart';

class DebugDetailErrorBody extends StatelessWidget {
  const DebugDetailErrorBody({super.key, required this.debugModel});

  final DebugModel debugModel;

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getPadding(context, 16);
    final gap = ResponsiveHelper.getSpacing(context, 20);
    final headers = debugModel.errorHeadersView();
    final underlying = debugModel.underlyingError;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        padding,
        padding,
        padding,
        padding + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        DebugSection(
          title: 'Error ${debugModel.errorStatusCode}',
          actionButton: CopyIconButton(
            text: debugModel.errorStatusMessage,
            label: 'Error message',
          ),
          children: [
            DebugCard(
              color: Colors.red.withValues(alpha: 0.08),
              borderColor: Colors.red.withValues(alpha: 0.3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_rounded,
                    color: Colors.red,
                    size: ResponsiveHelper.getFontSize(context, 22),
                  ),
                  SizedBox(width: ResponsiveHelper.getSpacing(context, 12)),
                  Expanded(
                    child: SelectableText(
                      debugModel.errorStatusMessage,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getFontSize(context, 13),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (underlying != null) ...[
          SizedBox(height: gap),
          DebugSection(
            title: 'Underlying Error',
            children: [
              DebugCard(
                child: SelectableText(
                  underlying,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontFamilyFallback: const ['Menlo', 'Courier'],
                    fontSize: ResponsiveHelper.getFontSize(context, 12),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (debugModel.hasResponseData) ...[
          SizedBox(height: gap),
          DebugSection(
            title: 'Error Body',
            children: [
              JsonBody(
                data: debugModel.responseData,
                emptyLabel: 'No error body',
              ),
            ],
          ),
        ],
        if (headers.isNotEmpty) ...[
          SizedBox(height: gap),
          DebugSection(
            title: 'Error Headers',
            trailingLabel: '${headers.length}',
            children: [HeaderList(headers: headers)],
          ),
        ],
      ],
    );
  }
}
