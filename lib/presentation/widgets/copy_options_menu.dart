import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logging_service/storage/debug_model.dart';
import 'package:logging_service/utils/copy_helper.dart';

class CopyOptionsMenu extends StatelessWidget {
  final DebugModel debugModel;

  const CopyOptionsMenu({
    super.key,
    required this.debugModel,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label copied to clipboard"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copy Request As',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 16.h),
              _buildOption(
                context,
                isDark,
                icon: Icons.terminal_rounded,
                title: 'cURL Command',
                subtitle: 'Terminal/Shell command',
                onTap: () => _copyToClipboard(
                  context,
                  CopyHelper.generateCurlCommand(debugModel),
                  'cURL Command',
                ),
              ),
              SizedBox(height: 8.h),
              _buildOption(
                context,
                isDark,
                icon: Icons.api_rounded,
                title: 'Postman Format',
                subtitle: 'Import to Postman',
                onTap: () => _copyToClipboard(
                  context,
                  CopyHelper.generatePostmanJson(debugModel),
                  'Postman JSON',
                ),
              ),
              SizedBox(height: 8.h),
              _buildOption(
                context,
                isDark,
                icon: Icons.data_object_rounded,
                title: 'JSON Format',
                subtitle: 'Complete request data',
                onTap: () => _copyToClipboard(
                  context,
                  CopyHelper.generateJsonRequest(debugModel),
                  'Request JSON',
                ),
              ),
              SizedBox(height: 16.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8.r),
          ),
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Icon(icon, size: 24.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.sp,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
