import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_view/json_view.dart';
import 'package:logging_service/storage/debug_model.dart';

class DebugDetailResponseBody extends StatelessWidget {
  final DebugModel debugModel;

  const DebugDetailResponseBody({super.key, required this.debugModel});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontWeight: FontWeight.w700, fontSize: 20);
    const rowStyle = TextStyle();
    return SingleChildScrollView(
      child: Column(
        children: [
          ListTile(
            title: const Text(
              "Status code",
              style: headerStyle,
            ),
            subtitle: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                backgroundColor: debugModel.statusCode.startsWith("2") ? Colors.green : Colors.red,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: debugModel.statusCode.startsWith("2") ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                label: Text(
                  debugModel.statusCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          if (debugModel.statusMessage.isNotEmpty)
            ListTile(
              title: const Text("Status message", style: rowStyle),
              subtitle: Text(
                debugModel.statusMessage,
                style: rowStyle,
              ),
            ),
          if (debugModel.responseData != null)
            ListTile(
              trailing: GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: debugModel.responseData.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Response copied to clipboard"),
                    ),
                  );
                },
                child: const Icon(Icons.copy, color: Colors.grey),
              ),
              title: const Text("Response", style: headerStyle),
              subtitle: debugModel.responseData is FormData
                  ? const Center(child: Text("Form Data is not supported yet"))
                  : JsonView(
                      json: debugModel.responseData,
                      shrinkWrap: true,
                    ),
            ),
          const Divider(),
          const ListTile(
            subtitle: Text(
              "HTTP HEADER FIELDS",
              style: headerStyle,
            ),
          ),
          const Divider(),
          Column(
            children: debugModel.responseHeaders.entries.map((e) {
              return ListTile(
                title: Text(e.key, style: rowStyle),
                subtitle: Text(
                  e.value.toString(),
                  style: rowStyle,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
