import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as liquid;
import 'package:material_ui/material_ui.dart';

const glassTabBarSpace = 79.0;

const glassPageInset = 16.0;
const glassItemGap = 12.0;

bool usesPremiumGlass(BuildContext context) =>
    liquid.GlassThemeData.of(context).qualityFor(context) ==
    liquid.GlassQuality.premium;

EdgeInsets sectionListPadding(
  BuildContext context, {
  bool floatingTabs = true,
}) => EdgeInsets.fromLTRB(
  glassPageInset,
  glassPageInset,
  glassPageInset,
  glassPageInset +
      MediaQuery.paddingOf(context).bottom +
      (floatingTabs ? glassTabBarSpace : 0),
);

class GlassNavigationBar extends StatelessWidget {
  const GlassNavigationBar({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final List<({IconData icon, String label})> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final premium = usesPremiumGlass(context);
    final primary = theme.colorScheme.primary;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(fontSize: 10);
    return liquid.GlassTabBar.bottom(
      selectedIndex: selectedIndex,
      onTabSelected: onSelected,
      horizontalPadding: 12,
      verticalPadding: 9,
      barHeight: 61,
      spacing: 3,
      tabPadding: const EdgeInsets.symmetric(horizontal: 2),
      iconSize: 21,
      enableBlend: premium || theme.platform != TargetPlatform.android,
      blendAmount: premium ? 5 : 10,
      settings: premium
          ? liquid.LiquidGlassSettings.ios27(context).copyWith(
              glassColor: dark
                  ? const Color(0x26CBDFF9)
                  : const Color(0x70F0F9FF),
              frost: dark ? 10 : 9,
              frostOpacity: dark ? .66 : .56,
              blur: .45,
              refractiveIndex: dark ? 1.21 : 1.19,
            )
          : null,
      indicatorColor: premium
          ? primary.withValues(alpha: dark ? .26 : .15)
          : null,
      indicatorSettings: premium
          ? liquid.LiquidGlassSettings.ios27Indicator.copyWith(
              glassColor: primary.withValues(alpha: dark ? .15 : .09),
              refractiveIndex: 1.21,
              rimLight: dark ? 1.18 : 1.12,
              rimShade: dark ? .23 : .42,
            )
          : null,
      selectedIconColor: primary,
      selectedLabelColor: primary,
      unselectedIconColor: theme.colorScheme.onSurface,
      unselectedLabelColor: theme.colorScheme.onSurface,
      selectedLabelStyle: labelStyle?.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: labelStyle,
      tabs: [
        for (final destination in destinations)
          liquid.GlassTab(
            icon: Icon(destination.icon),
            label: destination.label,
          ),
      ],
    );
  }
}
