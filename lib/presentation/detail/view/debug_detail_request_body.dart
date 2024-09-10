import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_view/json_view.dart';
import 'package:logging_service/storage/debug_model.dart';

class DebugDetailRequestBody extends StatelessWidget {
  final DebugModel debugModel;

  const DebugDetailRequestBody({super.key, required this.debugModel});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontWeight: FontWeight.w700);
    const rowStyle = TextStyle();

    return SingleChildScrollView(
      child: Column(
        children: [
          const ListTile(title: Text("REQUEST", style: headerStyle)),
          ListTile(
            title: const Text("URL", style: rowStyle),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    debugModel.url,
                    style: rowStyle,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: debugModel.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("URL copied to clipboard"),
                      ),
                    );
                  },
                  child: const Icon(Icons.copy, color: Colors.grey),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text("HTTP method", style: rowStyle),
            subtitle: Text(
              debugModel.httpMethod,
              style: rowStyle,
            ),
          ),
          ListTile(
            title: const Text("BODY", style: rowStyle),
            trailing: GestureDetector(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: debugModel.requestData.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Body copied to clipboard"),
                  ),
                );
              },
              child: const Icon(Icons.copy, color: Colors.grey),
            ),
            subtitle: debugModel.requestData is FormData
                ? const Center(child: Text("Form Data is not supported yet"))
                : JsonView(
                    shrinkWrap: true,
                    json: debugModel.requestData,
                  ),
          ),
          const Divider(),
          const ListTile(
            title: Text("HTTP HEADER FIELDS", style: headerStyle),
          ),
          Column(
            children: debugModel.requestHeaders.entries.map((e) {
              final index = debugModel.requestHeaders.keys.toList().indexOf(e.key);
              return ListTile(
                title: Text(e.key, style: rowStyle),
                trailing: index == 0 || index == 1 || index == 5
                    ? null
                    : GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: e.value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(" ${e.key} copied to clipboard"),
                            ),
                          );
                        },
                        child: const Icon(Icons.copy, color: Colors.grey),
                      ),
                subtitle: Text(
                  e.value,
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
