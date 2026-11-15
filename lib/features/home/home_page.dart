import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../core/storage/kp_en.dart';
import '../../core/theme/theme_mode_provider.dart';
import 'first_kp_provider.dart';

/// 首页（知识点读取 + 主题 / 适配能力的验收样例页）。
///
/// 四块内容：
/// 1. 知识点卡片 —— 从 asset/langly.db 的 kp_en 表读第一条数据（sqflite）；
/// 2. 外观模式卡片 —— Riverpod 管状态，三档切换 + Hive 持久化；
/// 3. 屏幕适配卡片 —— 真实使用 .w / .h / .r / .sp，并打印当前设备尺寸；
/// 4. 底部提示 —— 说明偏好已落盘。
/// 所有颜色都取自 ColorScheme，不写死黑白，深浅模式才不会漏。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch：知识点数据（FutureProvider），加载 / 失败 / 成功三态都在卡片里处理。
    final firstKp = ref.watch(firstKpProvider);
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
            _firstKpCard(scheme: scheme, state: firstKp),
            SizedBox(height: 16.h),
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

  /// 知识点卡片：把 kp_en 表第一条数据读出来展示。
  ///
  /// AsyncValue 三态都给可见反馈：
  /// - loading：首次复制 1.7 MB 种子库时给进度圈；
  /// - error  ：数据库 / asset 不可用时给降级文案，不红屏、不影响下面三张卡；
  /// - data   ：编号、原文、释义、标签、例句、要点速记 + 库内总数。
  Widget _firstKpCard({
    required ColorScheme scheme,
    required AsyncValue<FirstKpSnapshot> state,
  }) {
    return _card(
      scheme: scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded, size: 18.sp, color: scheme.primary),
              SizedBox(width: 8.w),
              Expanded(
                child: Text('SQLite 读取 · kp_en 表', style: _titleStyle(scheme)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          state.when(
            loading: () => Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10.w),
                  Text('正在打开 langly.db…', style: _bodyStyle(scheme)),
                ],
              ),
            ),
            error: (error, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded, size: 16.sp, color: scheme.error),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '数据库暂不可用，已跳过知识点卡片：$error',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _bodyStyle(scheme),
                  ),
                ),
              ],
            ),
            data: (snapshot) => _kpContent(scheme, snapshot),
          ),
        ],
      ),
    );
  }

  /// data 分支的实际内容：一条知识点的关键字段。
  Widget _kpContent(ColorScheme scheme, FirstKpSnapshot snapshot) {
    final KpEn? kp = snapshot.point;
    if (kp == null) {
      return _statusRow(
        scheme: scheme,
        icon: Icons.inbox_rounded,
        text: 'kp_en 表为空（共 ${snapshot.total} 条）',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _tagChip(scheme: scheme, text: kp.pointId),
            SizedBox(width: 6.w),
            _tagChip(scheme: scheme, text: kp.translationLang),
            const Spacer(),
            Text('共 ${snapshot.total} 条', style: _bodyStyle(scheme)),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          kp.pointContent,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(kp.translationContent.split('\n').first, style: _bodyStyle(scheme)),
        if (kp.tags.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: kp.tags
                .take(4)
                .map((tag) => _tagChip(scheme: scheme, text: tag))
                .toList(),
          ),
        ],
        if (kp.examples.isNotEmpty) ...[
          SizedBox(height: 14.h),
          Text('例句（前 3 条）', style: _sectionStyle(scheme)),
          SizedBox(height: 6.h),
          ...kp.examples.take(3).map(
                (example) => Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Text('• $example', style: _bodyStyle(scheme)),
                ),
              ),
        ],
        if (kp.keyPoint.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(
            kp.keyPoint.split('\n').first,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _bodyStyle(scheme),
          ),
        ],
        SizedBox(height: 10.h),
        _statusRow(
          scheme: scheme,
          icon: Icons.check_circle_outline_rounded,
          text: 'asset/langly.db → 应用文档目录 → sqflite 查询',
        ),
      ],
    );
  }

  /// 小标签：用 primaryContainer / onPrimaryContainer，避免品牌橙底配白字。
  Widget _tagChip({required ColorScheme scheme, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.sp, color: scheme.onPrimaryContainer),
      ),
    );
  }

  TextStyle _sectionStyle(ColorScheme scheme) => TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
    color: scheme.onSurface,
  );

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
          // 文案与 main.dart 的 kDesignSize（402×874）保持一致：
          // 基准尺寸改了，这行也要同步，避免界面上显示的是过期数值。
          Text('下面的尺寸与字号都按 402×874 设计稿等比换算。', style: _bodyStyle(scheme)),
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
