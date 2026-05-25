import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logging_service/storage/debug_model.dart';
import 'package:logging_service/utils/responsive_helper.dart';

class RetryDialog extends StatefulWidget {
  final DebugModel debugModel;
  final Dio dioClient;

  const RetryDialog({
    super.key,
    required this.debugModel,
    required this.dioClient,
  });

  @override
  State<RetryDialog> createState() => _RetryDialogState();
}

class _RetryDialogState extends State<RetryDialog> {
  bool isLoading = false;
  String? responseMessage;
  bool isSuccess = false;

  Future<void> _retryRequest() async {
    setState(() {
      isLoading = true;
      responseMessage = null;
      isSuccess = false;
    });

    try {
      final response = await widget.dioClient.request(
        widget.debugModel.url,
        options: Options(
          method: widget.debugModel.httpMethod,
          headers: widget.debugModel.requestHeaders,
        ),
        data: widget.debugModel.requestData,
      );

      setState(() {
        isSuccess = true;
        responseMessage =
            'Success! Status: ${response.statusCode}\n${response.statusMessage}';
      });
    } on DioException catch (e) {
      setState(() {
        isSuccess = false;
        responseMessage =
            'Error: ${e.response?.statusCode}\n${e.message}';
      });
    } catch (e) {
      setState(() {
        isSuccess = false;
        responseMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(
              ResponsiveHelper.getUIElementSize(context, 16)),
        ),
        child: Padding(
          padding: EdgeInsets.all(
              ResponsiveHelper.getPadding(context, 24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Retry Request',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(
                  height:
                      ResponsiveHelper.getSpacing(context, 8)),
              Text(
                widget.debugModel.path,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              SizedBox(
                  height:
                      ResponsiveHelper.getSpacing(context, 20)),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getUIElementSize(context, 8)),
                ),
                padding: EdgeInsets.all(
                    ResponsiveHelper.getPadding(context, 12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Details',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getSpacing(
                            context, 8)),
                    Text(
                      'Method: ${widget.debugModel.httpMethod}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    SizedBox(
                        height: ResponsiveHelper.getSpacing(
                            context, 4)),
                    Text(
                      'URL: ${widget.debugModel.url}',
                      style: Theme.of(context).textTheme.labelSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (responseMessage != null) ...[
                SizedBox(
                    height:
                        ResponsiveHelper.getSpacing(context, 16)),
                Container(
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    border: Border.all(
                      color: isSuccess
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getUIElementSize(
                            context, 8)),
                  ),
                  padding: EdgeInsets.all(
                      ResponsiveHelper.getPadding(context, 12)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: isSuccess ? Colors.green : Colors.red,
                        size: ResponsiveHelper.getFontSize(
                            context, 20),
                      ),
                      SizedBox(
                          width: ResponsiveHelper.getPadding(
                              context, 12)),
                      Expanded(
                        child: Text(
                          responseMessage!,
                          style: TextStyle(
                            color: isSuccess ? Colors.green : Colors.red,
                            fontSize: ResponsiveHelper.getFontSize(
                                context, 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(
                  height:
                      ResponsiveHelper.getSpacing(context, 24)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _retryRequest,
                    icon: isLoading
                        ? SizedBox(
                            width: ResponsiveHelper.getPadding(
                                context, 16),
                            height:
                                ResponsiveHelper.getSpacing(
                                    context, 16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(isLoading ? 'Retrying...' : 'Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
