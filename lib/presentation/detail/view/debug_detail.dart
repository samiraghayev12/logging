import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging_service/presentation/detail/model/debug_detail_view_model.dart';
import 'package:logging_service/presentation/detail/view/debug_detail_error_body.dart';
import 'package:logging_service/presentation/detail/view/debug_detail_request_body.dart';
import 'package:logging_service/presentation/detail/view/debug_detail_response_body.dart';
import 'package:logging_service/storage/debug_model.dart';

class DebugDetail extends StatefulWidget {
  final DebugModel debugModel;

  const DebugDetail({super.key, required this.debugModel});

  @override
  State<DebugDetail> createState() => _DebugDetailState();
}

class _DebugDetailState extends State<DebugDetail> {
  final viewModel = DebugDetailViewModel();

  @override
  void dispose() {
    viewModel.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Detail",
          style: TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
      body: StreamBuilder<DetailButton>(
        stream: viewModel.detailButtonStream,
        builder: (_, snapshot) {
          if (snapshot.data == DetailButton.request || snapshot.data == null) {
            return DebugDetailRequestBody(debugModel: widget.debugModel);
          } else {
            if (widget.debugModel.hasError) {
              return DebugDetailErrorBody(debugModel: widget.debugModel);
            } else {
              return DebugDetailResponseBody(debugModel: widget.debugModel);
            }
          }
        },
      ),
      persistentFooterButtons: [
        StreamBuilder<DetailButton>(
          stream: viewModel.detailButtonStream,
          builder: (context, snapshot) {
            return Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: snapshot.data == DetailButton.request || snapshot.data == null
                          ? CupertinoColors.activeBlue.withOpacity(0.2)
                          : Colors.transparent,
                      textStyle: const TextStyle(),
                    ),
                    onPressed: () => viewModel.choose(DetailButton.request),
                    child: const Text("REQUEST"),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: snapshot.data == DetailButton.response ? CupertinoColors.activeBlue.withOpacity(0.2) : Colors.transparent,
                      textStyle: const TextStyle(),
                    ),
                    onPressed: () => viewModel.choose(DetailButton.response),
                    child: Text(widget.debugModel.hasError ? "ERROR" : "RESPONSE"),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
