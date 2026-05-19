import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logging_service/presentation/detail/model/debug_detail_view_model.dart';
import 'package:logging_service/presentation/detail/view/debug_detail_error_body.dart';
import 'package:logging_service/presentation/detail/view/debug_detail_request_body.dart';
import 'package:logging_service/presentation/detail/view/debug_detail_response_body.dart';
import 'package:logging_service/presentation/widgets/copy_options_menu.dart';
import 'package:logging_service/presentation/widgets/retry_dialog.dart';
import 'package:logging_service/storage/debug_model.dart';

class DebugDetail extends StatefulWidget {
  final DebugModel debugModel;

  const DebugDetail({super.key, required this.debugModel});

  @override
  State<DebugDetail> createState() => _DebugDetailState();
}

class _DebugDetailState extends State<DebugDetail> with SingleTickerProviderStateMixin {
  final viewModel = DebugDetailViewModel();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    viewModel.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Request Details",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy_rounded),
            tooltip: 'Copy Request',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CopyOptionsMenu(debugModel: widget.debugModel),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Retry Request',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => RetryDialog(
                  debugModel: widget.debugModel,
                  dioClient: Dio(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          tabs: [
            const Tab(
              text: 'Request',
              icon: Icon(Icons.send_rounded, size: 18),
            ),
            Tab(
              text: widget.debugModel.hasError ? 'Error' : 'Response',
              icon: Icon(
                widget.debugModel.hasError
                    ? Icons.error_rounded
                    : Icons.check_circle_rounded,
                size: 18,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DebugDetailRequestBody(debugModel: widget.debugModel),
          widget.debugModel.hasError
              ? DebugDetailErrorBody(debugModel: widget.debugModel)
              : DebugDetailResponseBody(debugModel: widget.debugModel),
        ],
      ),
    );
  }
}
