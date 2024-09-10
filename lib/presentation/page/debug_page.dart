import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging_service/presentation/detail/view/debug_detail.dart';
import 'package:logging_service/storage/debug_storage.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  @override
  void initState() {
    HapticFeedback.lightImpact();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final debug = DebugStorage();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Network calls",
          style: TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: ListView.separated(
          separatorBuilder: (_, index) => const Divider(
            height: 1,
          ),
          itemBuilder: (_, index) {
            final request = debug.requests[index];
            return ListTile(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DebugDetail(
                    debugModel: request,
                  ),
                ),
              ),
              leading: Container(
                height: 30,
                width: 50,
                decoration: BoxDecoration(
                  color: request.httpMethodColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    request.httpMethod,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              subtitle: Text(
                request.requestTime ?? "",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              title: Text(
                request.path,
              ),
              trailing: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "${request.elapsedTime} ms",
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 6,
                    backgroundColor: request.hasError ? Colors.red : Colors.green,
                  ),
                ],
              ),
            );
          },
          itemCount: debug.requests.length,
        ),
      ),
    );
  }
}
