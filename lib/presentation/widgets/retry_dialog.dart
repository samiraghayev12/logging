import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../storage/debug_model.dart';
import '../../utils/log_formatter.dart';
import '../../utils/responsive_helper.dart';
import 'debug_section.dart';

class RetryDialog extends StatefulWidget {
  const RetryDialog({
    super.key,
    required this.debugModel,
    required this.dioClient,
  });

  final DebugModel debugModel;
  final Dio dioClient;

  @override
  State<RetryDialog> createState() => _RetryDialogState();
}

class _RetryDialogState extends State<RetryDialog> {
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _resultTitle;
  String? _resultBody;

  /// `content-length` kimi header-lər yeni sorğunu pozur — təmizlənir.
  static const Set<String> _strippedHeaders = {
    'content-length',
    'host',
    'connection',
  };

  Map<String, dynamic> get _retryHeaders {
    final headers = <String, dynamic>{};
    widget.debugModel.requestHeaders.forEach((key, dynamic value) {
      if (_strippedHeaders.contains(key.toLowerCase())) return;
      headers[key] = value;
    });
    return headers;
  }

  Future<void> _retryRequest() async {
    setState(() {
      _isLoading = true;
      _resultTitle = null;
      _resultBody = null;
      _isSuccess = false;
    });

    try {
      final response = await widget.dioClient.request<dynamic>(
        widget.debugModel.url,
        options: Options(
          method: widget.debugModel.httpMethod,
          headers: _retryHeaders,
          // 4xx/5xx exception atmasın — nəticəni özümüz göstəririk.
          validateStatus: (_) => true,
        ),
        data: widget.debugModel.requestData,
      );

      if (!mounted) return;
      final code = response.statusCode ?? 0;
      setState(() {
        _isSuccess = code >= 200 && code < 400;
        _resultTitle = 'Status $code ${response.statusMessage ?? ''}'.trim();
        _resultBody = LogFormatter.pretty(response.data);
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSuccess = false;
        _resultTitle = e.response?.statusCode != null
            ? 'Status ${e.response?.statusCode}'
            : e.type.name;
        _resultBody = e.message ?? '${e.error ?? ''}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSuccess = false;
        _resultTitle = 'Error';
        _resultBody = '$e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = widget.debugModel;
    final resultColor = _isSuccess ? Colors.green : Colors.red;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getPadding(context, 24),
        vertical: ResponsiveHelper.getPadding(context, 24),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Retry Request',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getFontSize(context, 17),
                    ),
              ),
              SizedBox(height: ResponsiveHelper.getSpacing(context, 12)),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KeyValueTile(
                        label: 'Method',
                        value: model.httpMethod,
                        copyable: false,
                      ),
                      SizedBox(height: ResponsiveHelper.getSpacing(context, 8)),
                      KeyValueTile(label: 'URL', value: model.url, maxLines: 4),
                      if (_resultTitle != null) ...[
                        SizedBox(
                          height: ResponsiveHelper.getSpacing(context, 12),
                        ),
                        DebugCard(
                          color: resultColor.withValues(alpha: 0.08),
                          borderColor: resultColor.withValues(alpha: 0.3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isSuccess
                                        ? Icons.check_circle_rounded
                                        : Icons.error_rounded,
                                    color: resultColor,
                                    size: ResponsiveHelper.getFontSize(context, 18),
                                  ),
                                  SizedBox(
                                    width:
                                        ResponsiveHelper.getSpacing(context, 8),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _resultTitle!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: resultColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: ResponsiveHelper.getFontSize(
                                          context,
                                          13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_resultBody != null &&
                                      _resultBody!.isNotEmpty)
                                    CopyIconButton(
                                      text: _resultBody!,
                                      label: 'Response',
                                    ),
                                ],
                              ),
                              if (_resultBody != null &&
                                  _resultBody!.trim().isNotEmpty) ...[
                                SizedBox(
                                  height:
                                      ResponsiveHelper.getSpacing(context, 8),
                                ),
                                Text(
                                  _resultBody!,
                                  maxLines: 12,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontFamilyFallback: const [
                                      'Menlo',
                                      'Courier'
                                    ],
                                    fontSize: ResponsiveHelper.getFontSize(
                                      context,
                                      11,
                                    ),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getSpacing(context, 16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  SizedBox(width: ResponsiveHelper.getSpacing(context, 8)),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _retryRequest,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(_isLoading ? 'Retrying…' : 'Retry'),
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
