import 'package:flutter/material.dart';

import '../../../storage/debug_model.dart';
import '../../../utils/log_formatter.dart';
import '../../../utils/responsive_helper.dart';
import '../../widgets/debug_section.dart';

class DebugDetailRequestBody extends StatelessWidget {
  const DebugDetailRequestBody({super.key, required this.debugModel});

  final DebugModel debugModel;

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getPadding(context, 16);
    final gap = ResponsiveHelper.getSpacing(context, 20);
    final headers = debugModel.requestHeadersView();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        padding,
        padding,
        padding,
        padding + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        DebugSection(
          title: 'URL',
          children: [
            DebugCard(
              child: SelectableText(
                debugModel.url,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(context, 12),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        DebugSection(
          title: 'General',
          children: [
            KeyValueTile(
              label: 'Method',
              value: debugModel.httpMethod,
              copyable: false,
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context, 8)),
            KeyValueTile(
              label: 'Started at',
              value: debugModel.requestTimeString,
              copyable: false,
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context, 8)),
            KeyValueTile(
              label: 'Connect timeout',
              value: debugModel.timeoutInterval,
              copyable: false,
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context, 8)),
            KeyValueTile(
              label: 'Content type',
              value: debugModel.contentType,
              copyable: false,
            ),
          ],
        ),
        if (debugModel.hasQueryParameters) ...[
          SizedBox(height: gap),
          DebugSection(
            title: 'Query Parameters',
            trailingLabel: '${debugModel.queryParameters.length}',
            children: [
              HeaderList(
                headers: LogFormatter.normalizeHeaders(
                  debugModel.queryParameters,
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: gap),
        DebugSection(
          title: debugModel.isFormDataRequest ? 'Request Body (FormData)' : 'Request Body',
          children: [
            JsonBody(
              data: debugModel.requestData,
              emptyLabel: 'No request body',
            ),
          ],
        ),
        SizedBox(height: gap),
        DebugSection(
          title: 'HTTP Headers',
          trailingLabel: '${headers.length}',
          children: [HeaderList(headers: headers)],
        ),
      ],
    );
  }
}
