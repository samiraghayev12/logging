import 'package:flutter/material.dart';

import '../../storage/debug_model.dart';
import '../../utils/copy_helper.dart';
import '../../utils/responsive_helper.dart';
import 'debug_section.dart';

class CopyOptionsMenu extends StatefulWidget {
  const CopyOptionsMenu({super.key, required this.debugModel});

  final DebugModel debugModel;

  @override
  State<CopyOptionsMenu> createState() => _CopyOptionsMenuState();
}

class _CopyOptionsMenuState extends State<CopyOptionsMenu> {
  bool _redact = true;

  void _copy(String text, String label) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    Navigator.of(context).pop();
    copyToClipboardWithMessenger(messenger, text, '$label copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = widget.debugModel;

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
          padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copy Request As',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getFontSize(context, 17),
                    ),
              ),
              SizedBox(height: ResponsiveHelper.getSpacing(context, 4)),
              SwitchListTile.adaptive(
                value: _redact,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => _redact = value),
                title: Text(
                  'Hide tokens',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, 13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Authorization / cookie header-lərini maskala',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, 11),
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _Option(
                      icon: Icons.terminal_rounded,
                      title: 'cURL Command',
                      subtitle: 'Terminal / shell command',
                      onTap: () => _copy(
                        CopyHelper.generateCurlCommand(model, redact: _redact),
                        'cURL command',
                      ),
                    ),
                    _Option(
                      icon: Icons.api_rounded,
                      title: 'Postman Collection',
                      subtitle: 'Import to Postman',
                      onTap: () => _copy(
                        CopyHelper.generatePostmanJson(model, redact: _redact),
                        'Postman JSON',
                      ),
                    ),
                    _Option(
                      icon: Icons.data_object_rounded,
                      title: 'JSON Format',
                      subtitle: 'Complete request + response',
                      onTap: () => _copy(
                        CopyHelper.generateJsonRequest(model, redact: _redact),
                        'Request JSON',
                      ),
                    ),
                    _Option(
                      icon: Icons.description_rounded,
                      title: 'Readable Summary',
                      subtitle: 'Bug report üçün mətn',
                      onTap: () => _copy(
                        CopyHelper.generateSummary(model, redact: _redact),
                        'Summary',
                      ),
                    ),
                    _Option(
                      icon: Icons.download_rounded,
                      title: 'Response Body',
                      subtitle: 'Yalnız cavab məzmunu',
                      enabled: model.hasResponseData,
                      onTap: () => _copy(
                        CopyHelper.generateResponseBody(model),
                        'Response body',
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: ResponsiveHelper.getSpacing(context, 8),
        ),
        child: Material(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getPadding(context, 12)),
              child: Row(
                children: [
                  Icon(icon, size: ResponsiveHelper.getUIElementSize(context, 22)),
                  SizedBox(width: ResponsiveHelper.getSpacing(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    ResponsiveHelper.getFontSize(context, 13),
                              ),
                        ),
                        SizedBox(height: ResponsiveHelper.getSpacing(context, 2)),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize:
                                    ResponsiveHelper.getFontSize(context, 11),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: ResponsiveHelper.getUIElementSize(context, 14),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
