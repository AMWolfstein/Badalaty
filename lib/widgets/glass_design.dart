import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoThemeData, CupertinoTextThemeData;
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as liquid;
import 'package:material_ui/material_ui.dart';

import 'glass_navigation_bar.dart';

ThemeData badalatyTheme(Brightness brightness, {required bool arabic}) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B77BB),
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFF9BD9FF) : const Color(0xFF145C95),
        onPrimary: dark ? const Color(0xFF102C40) : Colors.white,
        surface: dark ? const Color(0xFF182B43) : const Color(0xFFF5FAFF),
        onSurface: dark ? const Color(0xFFE9F5FD) : const Color(0xFF122540),
        onSurfaceVariant: dark
            ? const Color(0xFFBCD4E8)
            : const Color(0xFF465F79),
        primaryContainer: dark
            ? const Color(0xFF244968)
            : const Color(0xFFD5EEFF),
        onPrimaryContainer: dark
            ? const Color(0xFFBDEAFF)
            : const Color(0xFF124C78),
        outlineVariant: dark
            ? const Color(0xFF456680)
            : const Color(0xFFD2E5F6),
      );
  final rim = dark ? const Color(0xFF496783) : Colors.white;
  final panel = dark ? const Color(0xE9223B53) : const Color(0xEAF8FBFF);
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(19),
    side: BorderSide(color: rim),
  );
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(17),
    borderSide: BorderSide(color: rim),
  );
  final font = arabic ? 'Noto Sans Arabic' : 'Noto Sans';
  final fallbacks = [if (arabic) 'Noto Sans' else 'Noto Sans Arabic'];
  return ThemeData(
    fontFamily: font,
    fontFamilyFallback: fallbacks,
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: scheme.primary,
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(
          fontFamily: font,
          fontFamilyFallback: fallbacks,
          color: scheme.onSurface,
          fontSize: 16,
        ),
      ),
    ),
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarThemeData(
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallbacks,
        color: scheme.onSurface,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.24,
      ),
    ),
    cardTheme: CardThemeData(
      color: panel,
      surfaceTintColor: Colors.transparent,
      elevation: 1.5,
      shadowColor: const Color(0x22264D77),
      margin: const EdgeInsets.only(bottom: 10),
      shape: shape,
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: rim),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: panel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.primary,
      titleTextStyle: TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallbacks,
        color: scheme.onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.38,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallbacks,
        color: scheme.onSurfaceVariant,
        fontSize: 11,
        height: 1.4,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      minLeadingWidth: 34,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: TextStyle(
          fontFamily: font,
          fontFamilyFallback: fallbacks,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: TextStyle(
          fontFamily: font,
          fontFamilyFallback: fallbacks,
          fontWeight: FontWeight.w700,
        ),
        minimumSize: const Size(48, 48),
        backgroundColor: scheme.primaryContainer,
        side: BorderSide(color: rim),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    super.key,
  });

  final GlassHeader? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final floatingTabs = bottomNavigationBar != null;
    final safeTop = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).appBarTheme.systemOverlayStyle!,
      child: Material(
        type: MaterialType.transparency,
        child: liquid.GlassScaffold(
          background: const RepaintBoundary(child: _GlassBackground()),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          extendBody: floatingTabs,
          topEdgeFade: false,
          appBarHeight: GlassHeader.height,
          bottomBarHeight: glassTabBarSpace,
          appBar: appBar,
          bottomBar: bottomNavigationBar,
          body: appBar == null
              ? body
              : Padding(
                  padding: EdgeInsets.only(
                    top: floatingTabs ? safeTop + GlassHeader.height : 0,
                  ),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: body,
                  ),
                ),
        ),
      ),
    );
  }
}

class GlassHeader extends StatelessWidget {
  const GlassHeader({required this.title, this.actions = const [], super.key});

  static const height = 56.0;
  final Widget title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => liquid.GlassAppBar(
    toolbarHeight: height,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    title: DefaultTextStyle.merge(
      style: Theme.of(context).textTheme.titleLarge,
      child: title,
    ),
    centerTitle: false,
    leading: ModalRoute.of(context)?.canPop == true
        ? Tooltip(
            message: MaterialLocalizations.of(context).backButtonTooltip,
            child: liquid.GlassIconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          )
        : null,
    actions: actions,
  );
}

class GlassContentCard extends StatelessWidget {
  const GlassContentCard({required this.child, this.color, super.key});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) => liquid.GlassContainer.card(
    color: color,
    surfaceStyle: liquid.GlassSurfaceStyle.solid,
    shape: const liquid.LiquidRoundedSuperellipse(borderRadius: 25),
    margin: const EdgeInsets.only(bottom: 10),
    padding: EdgeInsets.zero,
    child: child,
  );
}

class GlassRow extends StatelessWidget {
  const GlassRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return liquid.GlassListTile(
      leading: leading,
      trailing: trailing,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      onLongPress: onLongPress,
      titleStyle: theme.textTheme.bodyLarge,
      subtitleStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class GlassToggleRow extends StatelessWidget {
  const GlassToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.secondary,
    this.subtitle,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? secondary;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) => GlassRow(
    leading: secondary,
    title: Text(label),
    subtitle: subtitle,
    onTap: onChanged == null ? null : () => onChanged!(!value),
    trailing: liquid.GlassSwitch(
      value: value,
      onChanged: onChanged,
      semanticLabel: label,
    ),
  );
}

class GlassAction extends StatelessWidget {
  const GlassAction({required this.onPressed, required Widget child, super.key})
    : label = child,
      icon = null;

  const GlassAction.icon({
    required this.onPressed,
    required this.icon,
    required this.label,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget label;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = onPressed == null
        ? scheme.onSurfaceVariant
        : scheme.onPrimary;
    return liquid.GlassButton.custom(
      onTap: onPressed ?? () {},
      enabled: onPressed != null,
      height: 49,
      color: onPressed == null ? scheme.surfaceContainerHigh : scheme.primary,
      shape: const liquid.LiquidRoundedSuperellipse(borderRadius: 19),
      surfaceStyle: liquid.GlassSurfaceStyle.solid,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
          child: IconTheme(
            data: IconThemeData(color: foreground, size: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 7,
              children: [
                ?icon,
                Flexible(child: label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassBackground extends StatelessWidget {
  const _GlassBackground();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: dark
              ? const [Color(0xFF204560), Color(0xFF17243D), Color(0xFF101D30)]
              : const [Color(0xFFC9EAF9), Color(0xFFF0F7FF), Color(0xFFE1EEF9)],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-1.0, -0.20),
            radius: 0.95,
            colors: dark
                ? const [Color(0x80352E5B), Color(0x00352E5B)]
                : const [Color(0xA4DFD9F8), Color(0x00DFD9F8)],
          ),
        ),
      ),
    );
  }
}

class GlassIcon extends StatelessWidget {
  const GlassIcon(this.icon, {this.tone = 0, super.key});

  final IconData icon;
  final int tone;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (fill, ink) = switch (tone) {
      1 =>
        dark
            ? (const Color(0xFF514371), const Color(0xFFE8D7FF))
            : (const Color(0xFFEBE4FB), const Color(0xFF664C96)),
      2 =>
        dark
            ? (const Color(0xFF23515E), const Color(0xFFA4E8EE))
            : (const Color(0xFFD6F4F6), const Color(0xFF126B75)),
      _ =>
        dark
            ? (const Color(0xFF275274), const Color(0xFFB2E7FF))
            : (const Color(0xFFD5EFFF), const Color(0xFF14699E)),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(11),
      ),
      child: SizedBox.square(
        dimension: 34,
        child: Icon(icon, color: ink, size: 19),
      ),
    );
  }
}

class GlassHeading extends StatelessWidget {
  const GlassHeading(this.title, {this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 11, bottom: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        ?action,
      ],
    ),
  );
}

class GlassHighlight extends StatelessWidget {
  const GlassHighlight({
    required this.label,
    required this.value,
    this.detail,
    this.unit,
    this.isBalance = true,
    super.key,
  });

  final String label;
  final String value;
  final Widget? detail;
  final String? unit;
  final bool isBalance;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(25);
    final valueStyle = TextStyle(
      color: Colors.white,
      fontSize: isBalance ? 36 : 21,
      height: 1.15,
      fontWeight: FontWeight.w700,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x3A164879),
            blurRadius: 17,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: const Color(0xFF82BDE4)),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.topRight,
              colors: [Color(0xFF0B729C), Color(0xFF103065), Color(0xFF152D60)],
            ),
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                end: -111,
                top: -85,
                child: ExcludeSemantics(
                  child: Container(
                    width: 236,
                    height: 236,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0x45C2ECFF),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x316ECAFF),
                          blurRadius: 20,
                          spreadRadius: 11,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.fontFamily,
                    fontFamilyFallback: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.fontFamilyFallback,
                    color: const Color(0xFFD5ECFF),
                    fontSize: 12,
                    height: 1.4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(label),
                      const SizedBox(height: 3),
                      if (unit case final unit?)
                        Row(
                          spacing: 6,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(child: Text(value, style: valueStyle)),
                            Text(unit),
                          ],
                        )
                      else
                        Text(value, style: valueStyle),
                      if (detail != null) ...[
                        const Divider(color: Color(0x52BBE4FF), height: 16),
                        detail!,
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassPanelDialog extends StatelessWidget {
  const GlassPanelDialog({
    this.title,
    this.content,
    this.actions = const [],
    this.scrollable = false,
    super.key,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget> actions;
  final bool scrollable;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: liquid.GlassContainer.card(
        useOwnLayer: true,
        shape: const liquid.LiquidRoundedSuperellipse(borderRadius: 29),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            if (title != null)
              DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.titleLarge,
                child: title!,
              ),
            if (content != null)
              Flexible(
                child: scrollable
                    ? SingleChildScrollView(child: content)
                    : content!,
              ),
            if (actions.isNotEmpty)
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 6,
                children: actions,
              ),
          ],
        ),
      ),
    ),
  );
}

class GlassFilterChip extends StatelessWidget {
  const GlassFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return liquid.GlassChip(
      label: label,
      selected: selected,
      onTap: onTap,
      labelStyle: theme.textTheme.labelLarge,
      selectedColor: theme.colorScheme.primaryContainer,
      surfaceStyle: liquid.GlassSurfaceStyle.solid,
    );
  }
}

class GlassOverflow<T> extends StatelessWidget {
  const GlassOverflow({
    required this.label,
    required this.items,
    required this.onSelected,
    this.destructiveValue,
    super.key,
  });

  final String label;
  final Map<T, String> items;
  final ValueChanged<T> onSelected;
  final T? destructiveValue;

  @override
  Widget build(BuildContext context) => liquid.GlassPullDownButton(
    icon: const Icon(Icons.more_horiz),
    semanticLabel: label,
    menuSemanticLabel: label,
    items: [
      for (final item in items.entries)
        liquid.GlassMenuItem(
          title: item.value,
          isDestructive: item.key == destructiveValue,
          onTap: () => onSelected(item.key),
        ),
    ],
  );
}

class GlassIconAction extends StatelessWidget {
  const GlassIconAction({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.floating = false,
    super.key,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool floating;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: liquid.GlassIconButton(
      icon: icon,
      onPressed: onPressed,
      semanticLabel: tooltip,
      size: 44,
      iconSize: 20,
      surfaceStyle: floating
          ? liquid.GlassSurfaceStyle.glass
          : liquid.GlassSurfaceStyle.solid,
    ),
  );
}

class GlassSecondaryAction extends StatelessWidget {
  const GlassSecondaryAction({
    required this.onPressed,
    required this.child,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return liquid.GlassButton.custom(
      onTap: onPressed ?? () {},
      enabled: onPressed != null,
      height: 46,
      surfaceStyle: liquid.GlassSurfaceStyle.solid,
      color: scheme.surfaceContainerHigh,
      shape: const liquid.LiquidRoundedSuperellipse(borderRadius: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: scheme.onSurface),
          child: child,
        ),
      ),
    );
  }
}

class GlassContentGroup extends StatelessWidget {
  const GlassContentGroup({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => liquid.GlassGroupedSection(
    surfaceStyle: liquid.GlassSurfaceStyle.solid,
    children: children,
  );
}
