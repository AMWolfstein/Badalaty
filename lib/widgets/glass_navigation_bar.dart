import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as liquid;
import 'package:material_ui/material_ui.dart';

const glassTabBarSpace = 79.0;

EdgeInsets sectionListPadding(BuildContext context) => EdgeInsets.fromLTRB(
  16,
  16,
  16,
  16 +
      MediaQuery.paddingOf(context).bottom +
      (ModalRoute.of(context)?.canPop == true ? 0 : glassTabBarSpace),
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
      selectedIconColor: theme.colorScheme.primary,
      selectedLabelColor: theme.colorScheme.primary,
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
