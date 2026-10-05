import 'package:flutter/material.dart';

import '../../environment/debug_environment.dart';
import '../../utils/responsive_helper.dart';

/// Short label for an environment name, used on the button badge.
String environmentBadge(String name) =>
    (name.length > 3 ? name.substring(0, 3) : name).toUpperCase();

/// A small line under the log page title: "● Dev ▾". Opens the switcher.
/// Hidden when no environments are configured.
class EnvironmentSubtitle extends StatelessWidget {
  const EnvironmentSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final registry = DebugEnvironments.instance;
    return ListenableBuilder(
      listenable: registry,
      builder: (context, _) {
        if (registry.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final selected = registry.selected;
        final color = selected == null
            ? theme.colorScheme.outline
            : (registry.byName(selected).first.color ??
                  theme.colorScheme.primary);
        return Semantics(
          button: true,
          label: 'Switch environment',
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => showEnvironmentSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      selected ?? 'Default environment',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: ResponsiveHelper.getFontSize(context, 12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Opens the environment switcher.
Future<void> showEnvironmentSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _EnvironmentSheet(),
  );
}

class _EnvironmentSheet extends StatelessWidget {
  const _EnvironmentSheet();

  Future<void> _select(BuildContext context, String? name) async {
    final registry = DebugEnvironments.instance;
    if (name == registry.selected) {
      Navigator.of(context).pop();
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    await registry.select(name);
    if (context.mounted) Navigator.of(context).pop();
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            name == null
                ? 'Using the app\'s own base URLs'
                : 'Switched to $name — new requests use its base URL',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registry = DebugEnvironments.instance;
    final selected = registry.selected;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text('Environment', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Changes the base URL of new requests. Saved until you switch back.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _EnvironmentOption(
              title: 'Default',
              urls: const ['Base URLs configured in the app'],
              color: theme.colorScheme.outline,
              selected: selected == null,
              onTap: () => _select(context, null),
            ),
            for (final name in registry.names)
              _EnvironmentOption(
                title: name,
                urls: [for (final env in registry.byName(name)) env.baseUrl],
                color:
                    registry.byName(name).first.color ??
                    theme.colorScheme.primary,
                selected: selected == name,
                onTap: () => _select(context, name),
              ),
          ],
        ),
      ),
    );
  }
}

class _EnvironmentOption extends StatelessWidget {
  const _EnvironmentOption({
    required this.title,
    required this.urls,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final List<String> urls;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? color : theme.dividerColor,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? color : theme.colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    for (final url in urls)
                      Text(
                        url,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
