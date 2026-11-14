import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../core/theme/theme_mode_provider.dart';

/// 首页（当前是主题 / 适配能力的验收样例页）。
///
/// 三块内容分别对应这次接进来的三件事：
/// 1. 外观模式卡片 —— Riverpod 管状态，三档切换 + Hive 持久化；
/// 2. 屏幕适配卡片 —— 真实使用 .w / .h / .r / .sp，并打印当前设备尺寸；
/// 3. 底部提示 —— 说明偏好已落盘。
/// 所有颜色都取自 ColorScheme，不写死黑白，深浅模式才不会漏。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch：模式一变，这里就重建，MaterialApp 里的 themeMode 随之刷新。
    final mode = ref.watch(themeModeProvider);
    // read：只在按钮回调里用，不参与重建。
    final notifier = ref.read(themeModeProvider.notifier);

    final scheme = Theme.of(context).colorScheme;
    final effectiveBrightness = Theme.of(context).brightness;
    final isDark = effectiveBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Langly',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '切换主题：跟随系统 / 浅色 / 深色',
            icon: Icon(_iconFor(mode), size: 22.sp),
            onPressed: notifier.cycle,
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _themeCard(
              scheme: scheme,
              mode: mode,
              isDark: isDark,
              onChanged: notifier.setMode,
            ),
            SizedBox(height: 16.h),
            _screenUtilCard(scheme: scheme),
            SizedBox(height: 16.h),
            _storageHint(scheme: scheme),
          ],
        ),
      ),
    );
  }

  /// 外观模式卡片：三档 SegmentedButton + 当前状态说明。
  Widget _themeCard({
    required ColorScheme scheme,
    required ThemeMode mode,
    required bool isDark,
    required ValueChanged<ThemeMode> onChanged,
  }) {
    return _card(
      scheme: scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('外观模式', style: _titleStyle(scheme)),
          SizedBox(height: 6.h),
          Text('切换后立刻生效，并写入 Hive；重启 App 仍保持。', style: _bodyStyle(scheme)),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              // 用两字短标签 + 小图标，避免窄屏下 SegmentedButton 溢出。
              segments: <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_rounded, size: 18.sp),
                  label: Text('系统', style: TextStyle(fontSize: 12.sp)),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_rounded, size: 18.sp),
                  label: Text('浅色', style: TextStyle(fontSize: 12.sp)),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded, size: 18.sp),
                  label: Text('深色', style: TextStyle(fontSize: 12.sp)),
                ),
              ],
              selected: <ThemeMode>{mode},
              onSelectionChanged: (selection) => onChanged(selection.first),
            ),
          ),
          SizedBox(height: 14.h),
          _statusRow(
            scheme: scheme,
            icon: Icons.tune_rounded,
            text: '当前选择：${_labelFor(mode)}',
          ),
          SizedBox(height: 6.h),
          _statusRow(
            scheme: scheme,
            icon: isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
            text:
                '实际生效：${isDark ? '深色' : '浅色'}'
                '${mode == ThemeMode.system ? '（由系统决定）' : ''}',
          ),
        ],
      ),
    );
  }

  /// 屏幕适配卡片：真实使用 screenutil_plus 的四个单位，并显示当前设备换算比。
  Widget _screenUtilCard({required ColorScheme scheme}) {
    final su = ScreenUtilPlus();
    return _card(
      scheme: scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('屏幕适配 · flutter_screenutil_plus', style: _titleStyle(scheme)),
          SizedBox(height: 6.h),
          Text('下面的尺寸与字号都按 390×844 设计稿等比换算。', style: _bodyStyle(scheme)),
          SizedBox(height: 14.h),
          Container(
            width: 150.w,
            height: 56.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '150.w × 56.h',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: scheme.onPrimary,
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            '16.sp 主文字',
            style: TextStyle(fontSize: 16.sp, color: scheme.onSurface),
          ),
          SizedBox(height: 6.h),
          Text(
            '12.sp 辅助说明',
            style: TextStyle(fontSize: 12.sp, color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: 14.h),
          Text(
            '设备 ${su.screenWidth.toStringAsFixed(1)} × '
            '${su.screenHeight.toStringAsFixed(1)} dp  ·  '
            '宽度缩放比 ${su.scaleWidth.toStringAsFixed(3)}',
            style: _bodyStyle(scheme),
          ),
        ],
      ),
    );
  }

  /// 底部提示：说明偏好已经落到本地。
  Widget _storageHint({required ColorScheme scheme}) {
    return _card(
      scheme: scheme,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.save_rounded, size: 18.sp, color: scheme.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '主题偏好保存在 Hive 的 settings Box 中，'
              '不依赖网络，冷启动后会先读回再渲染界面。',
              style: _bodyStyle(scheme),
            ),
          ),
        ],
      ),
    );
  }

  /// 统一的卡片外壳：边框用 outlineVariant，深浅模式下都会自动换色。
  Widget _card({required ColorScheme scheme, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: child,
    );
  }

  Widget _statusRow({
    required ColorScheme scheme,
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: scheme.primary),
        SizedBox(width: 8.w),
        Expanded(child: Text(text, style: _bodyStyle(scheme))),
      ],
    );
  }

  TextStyle _titleStyle(ColorScheme scheme) => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
    color: scheme.onSurface,
  );

  TextStyle _bodyStyle(ColorScheme scheme) =>
      TextStyle(fontSize: 13.sp, height: 1.4, color: scheme.onSurfaceVariant);

  /// 三档对应的快捷按钮图标。
  IconData _iconFor(ThemeMode mode) => switch (mode) {
    ThemeMode.system => Icons.brightness_auto_rounded,
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
  };

  /// 三档对应的中文名。
  String _labelFor(ThemeMode mode) => switch (mode) {
    ThemeMode.system => '跟随系统',
    ThemeMode.light => '浅色',
    ThemeMode.dark => '深色',
  };
}
