import 'package:flutter/material.dart';

import '../../../service/network_logger.dart';
import '../../../storage/debug_model.dart';
import '../../../storage/debug_storage.dart';
import '../../../utils/responsive_helper.dart';
import '../../widgets/copy_options_menu.dart';
import '../../widgets/debug_section.dart';
import '../../widgets/retry_dialog.dart';
import 'debug_detail_error_body.dart';
import 'debug_detail_request_body.dart';
import 'debug_detail_response_body.dart';

class DebugDetail extends StatefulWidget {
  const DebugDetail({super.key, required this.debugModel});

  final DebugModel debugModel;

  @override
  State<DebugDetail> createState() => _DebugDetailState();
}

class _DebugDetailState extends State<DebugDetail>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.clampTextScale(
      context,
      ListenableBuilder(
        listenable: DebugStorage(),
        builder: (context, _) => _buildScaffold(context),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final model = widget.debugModel;
    final hasError = model.hasError;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        title: Text(
          'Request Details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, 20),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy_rounded),
            tooltip: 'Copy request',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => CopyOptionsMenu(debugModel: model),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Retry request',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => RetryDialog(
                debugModel: model,
                dioClient: NetworkLogger.createRetryClient(),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getFontSize(context, 14),
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.getFontSize(context, 14),
          ),
          tabs: [
            Tab(
              height: ResponsiveHelper.getUIElementSize(context, 46),
              icon: Icon(
                Icons.send_rounded,
                size: ResponsiveHelper.getUIElementSize(context, 18),
              ),
              child: const Text(
                'Request',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Tab(
              height: ResponsiveHelper.getUIElementSize(context, 46),
              icon: Icon(
                hasError ? Icons.error_rounded : Icons.check_circle_rounded,
                size: ResponsiveHelper.getUIElementSize(context, 18),
              ),
              child: Text(
                hasError ? 'Error' : 'Response',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveHelper.constrain(
          context,
          Column(
            children: [
              _SummaryHeader(model: model),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    DebugDetailRequestBody(debugModel: model),
                    hasError
                        ? DebugDetailErrorBody(debugModel: model)
                        : DebugDetailResponseBody(debugModel: model),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.model});

  final DebugModel model;

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getPadding(context, 16);

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, padding * 0.75, padding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getPadding(context, 8),
                  vertical: ResponsiveHelper.getPadding(context, 4),
                ),
                decoration: BoxDecoration(
                  color: model.httpMethodColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  model.httpMethod,
                  maxLines: 1,
                  style: TextStyle(
                    color: model.httpMethodColor,
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getFontSize(context, 12),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getSpacing(context, 8)),
              Expanded(
                child: Text(
                  model.url,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, 12),
                    height: 1.35,
                  ),
                ),
              ),
              CopyIconButton(text: model.url, label: 'URL'),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context, 10)),
          Wrap(
            spacing: ResponsiveHelper.getSpacing(context, 8),
            runSpacing: ResponsiveHelper.getSpacing(context, 8),
            children: [
              InfoChip(
                icon: model.isPending
                    ? Icons.hourglass_top_rounded
                    : (model.hasError
                        ? Icons.error_rounded
                        : Icons.check_circle_rounded),
                label: model.statusCode,
                color: model.statusColor,
              ),
              InfoChip(
                icon: Icons.timer_outlined,
                label: model.elapsedTimeInMs,
                color: model.durationColor,
              ),
              InfoChip(
                icon: Icons.upload_rounded,
                label: model.requestSizeLabel,
                color: Colors.blueGrey,
              ),
              InfoChip(
                icon: Icons.download_rounded,
                label: model.responseSizeLabel,
                color: Colors.blueGrey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
