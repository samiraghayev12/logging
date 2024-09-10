import 'package:flutter/material.dart';
import 'package:logging_service/storage/debug_model.dart';

class DebugDetailErrorBody extends StatelessWidget {
  final DebugModel debugModel;

  const DebugDetailErrorBody({super.key, required this.debugModel});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.w700,
    );
    const rowStyle = TextStyle();

    return ListView(
      children: [
        const ListTile(subtitle: Text("ERROR", style: headerStyle)),
        const Divider(),
        ListTile(
          title: const Text("Status code", style: rowStyle),
          subtitle: Text(
            debugModel.errorStatusCode,
            style: rowStyle,
          ),
        ),
        if (debugModel.statusMessage.isNotEmpty)
          ListTile(
            title: const Text("Status message", style: rowStyle),
            subtitle: Text(
              debugModel.errorStatusMessage,
              style: rowStyle,
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
          children: debugModel.errorHeaders.entries.map((e) {
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
    );
  }
}
