import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_colors.dart';

class WrSearchBar extends StatelessWidget {
  final String placeholder;
  final String? rightLabel;
  final VoidCallback? onTap;
  final VoidCallback? onRightTap;

  const WrSearchBar({
    super.key,
    this.placeholder = '搜索',
    this.rightLabel = '书城',
    this.onTap,
    this.onRightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: onTap ?? () => context.push('/search'),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.searchBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search, size: 18, color: AppColors.textHint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  placeholder,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                ),
              ),
              if (rightLabel != null) ...[
                Container(
                  width: 1,
                  height: 16,
                  color: AppColors.border,
                ),
                GestureDetector(
                  onTap: onRightTap ?? () => context.go('/discover'),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      rightLabel!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
