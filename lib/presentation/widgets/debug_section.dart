import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_view/json_view.dart';

import '../../utils/log_formatter.dart';
import '../../utils/responsive_helper.dart';

/// Detal səhifələrində istifadə olunan ortaq UI parçaları.
class DebugSection extends StatelessWidget {
  const DebugSection({
    super.key,
    required this.title,
    required this.children,
    this.actionButton,
    this.trailingLabel,
  });

  final String title;
  final List<Widget> children;
  final Widget? actionButton;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getFontSize(context, 15),
                    ),
              ),
            ),
            if (trailingLabel != null)
              Padding(
                padding: EdgeInsets.only(
                  left: ResponsiveHelper.getSpacing(context, 8),
                ),
                child: Text(
                  trailingLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: ResponsiveHelper.getFontSize(context, 11),
                        color: Colors.grey[600],
                      ),
                ),
              ),
            if (actionButton != null) actionButton!,
          ],
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context, 8)),
        ...children,
      ],
    );
  }
}

/// Sərhədli, açıq fonlu qutu.
class DebugCard extends StatelessWidget {
  const DebugCard({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.padding,
  });

  final Widget child;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding ??
          EdgeInsets.all(ResponsiveHelper.getPadding(context, 12)),
      decoration: BoxDecoration(
        color: color ?? (isDark ? Colors.grey[900] : Colors.grey[50]),
        border: Border.all(
          color: borderColor ??
              (isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

/// Uzun mətnlərin daşmadan göstərildiyi açar/dəyər sətri.
class KeyValueTile extends StatelessWidget {
  const KeyValueTile({
    super.key,
    required this.label,
    required this.value,
    this.maxLines = 4,
    this.copyable = true,
  });

  final String label;
  final String value;
  final int maxLines;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return DebugCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getFontSize(context, 12),
                      ),
                ),
                SizedBox(height: ResponsiveHelper.getSpacing(context, 4)),
                Text(
                  value.isEmpty ? '—' : value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: ResponsiveHelper.getFontSize(context, 12),
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          if (copyable) ...[
            SizedBox(width: ResponsiveHelper.getSpacing(context, 6)),
            CopyIconButton(text: value, label: label),
          ],
        ],
      ),
    );
  }
}

/// Header siyahısı — həm request, həm response üçün.
class HeaderList extends StatelessWidget {
  const HeaderList({super.key, required this.headers});

  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    final entries = headers.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    if (entries.isEmpty) {
      return const DebugCard(child: Text('—'));
    }

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          KeyValueTile(label: entries[i].key, value: entries[i].value),
          if (i != entries.length - 1)
            SizedBox(height: ResponsiveHelper.getSpacing(context, 8)),
        ],
      ],
    );
  }
}

/// Kopyalama düyməsi — SnackBar-ı təhlükəsiz göstərir.
class CopyIconButton extends StatelessWidget {
  const CopyIconButton({
    super.key,
    required this.text,
    required this.label,
    this.size,
  });

  final String text;
  final String label;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? ResponsiveHelper.getUIElementSize(context, 18);
    return IconButton(
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints.tightFor(
        width: iconSize * 2,
        height: iconSize * 2,
      ),
      padding: EdgeInsets.zero,
      icon: Icon(Icons.copy_rounded, size: iconSize),
      tooltip: 'Copy $label',
      onPressed: () => copyToClipboard(context, text, label),
    );
  }
}

void copyToClipboard(BuildContext context, String text, String label) {
  copyToClipboardWithMessenger(
    ScaffoldMessenger.maybeOf(context),
    text,
    '$label copied',
  );
}

/// Dialoq bağlandıqdan sonra da SnackBar göstərə bilmək üçün messenger
/// əvvəlcədən alınıb ötürülür.
void copyToClipboardWithMessenger(
  ScaffoldMessengerState? messenger,
  String text,
  String message,
) {
  Clipboard.setData(ClipboardData(text: text));
  messenger?.showSnackBar(
    SnackBar(
      content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

/// JSON body — ağac / xam mətn arasında keçid edir və heç vaxt daşmır.
class JsonBody extends StatefulWidget {
  const JsonBody({super.key, required this.data, required this.emptyLabel});

  final Object? data;
  final String emptyLabel;

  @override
  State<JsonBody> createState() => _JsonBodyState();
}

class _JsonBodyState extends State<JsonBody> {
  bool _raw = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parsed = LogFormatter.forJsonView(widget.data);
    final rawText = LogFormatter.pretty(widget.data);
    final isTree = parsed is Map || parsed is List;

    if (widget.data == null || rawText.trim().isEmpty) {
      return DebugCard(
        child: Text(
          widget.emptyLabel,
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, 12),
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                LogFormatter.humanBytes(
                  LogFormatter.byteSize(widget.data) ?? rawText.length,
                ),
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(context, 11),
                  color: Colors.grey[600],
                ),
              ),
            ),
            if (isTree)
              TextButton.icon(
                onPressed: () => setState(() => _raw = !_raw),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getPadding(context, 8),
                  ),
                ),
                icon: Icon(
                  _raw ? Icons.account_tree_rounded : Icons.notes_rounded,
                  size: ResponsiveHelper.getUIElementSize(context, 16),
                ),
                label: Text(
                  _raw ? 'Tree' : 'Raw',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, 12),
                  ),
                ),
              ),
            CopyIconButton(text: rawText, label: 'Body'),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context, 6)),
        DebugCard(
          child: (!isTree || _raw)
              ? SelectableText(
                  rawText,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontFamilyFallback: const ['Menlo', 'Courier'],
                    fontSize: ResponsiveHelper.getFontSize(context, 12),
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFF9ED9A6)
                        : const Color(0xFF10391B),
                  ),
                )
              : JsonView(
                  json: parsed,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  styleScheme: JsonStyleScheme(
                    keysStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF79C0FF)
                          : const Color(0xFF0550AE),
                      fontSize: ResponsiveHelper.getFontSize(context, 12),
                      fontWeight: FontWeight.w600,
                    ),
                    valuesStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF85E89D)
                          : const Color(0xFF033A16),
                      fontSize: ResponsiveHelper.getFontSize(context, 12),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Kiçik məlumat çipi (status, müddət, ölçü və s.).
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getPadding(context, 10),
        vertical: ResponsiveHelper.getPadding(context, 6),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: ResponsiveHelper.getUIElementSize(context, 14), color: color),
          SizedBox(width: ResponsiveHelper.getSpacing(context, 6)),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getFontSize(context, 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
