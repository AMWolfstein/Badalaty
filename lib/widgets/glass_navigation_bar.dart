import 'package:material_ui/material_ui.dart';

EdgeInsets sectionListPadding(BuildContext context) =>
    EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom);

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
    final highContrast = MediaQuery.highContrastOf(context);
    final radius = BorderRadius.circular(28);
    final surface = dark ? const Color(0xFF12223A) : const Color(0xFFEAF5FF);
    final foreground = dark ? const Color(0xFFD6E5F7) : const Color(0xFF29465F);
    final selectedFill = dark
        ? const Color(0xFF194964)
        : const Color(0xFFBDE9FA);
    final selectedInk = dark
        ? const Color(0xFFA9EDFF)
        : const Color(0xFF0A4C69);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF07182B)
                    .withValues(alpha: dark ? .44 : .18),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    surface.withValues(alpha: highContrast ? 1 : .96),
                    surface.withValues(alpha: highContrast ? 1 : .9),
                  ],
                ),
                borderRadius: radius,
                border: Border.all(
                  color: dark ? const Color(0xFF476987) : Colors.white,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Row(
                  spacing: 4,
                  children: [
                    for (final (index, destination) in destinations.indexed)
                      Expanded(
                        child: _GlassTab(
                          label: destination.label,
                          icon: destination.icon,
                          selected: index == selectedIndex,
                          foreground: index == selectedIndex
                              ? selectedInk
                              : foreground,
                          fill: selectedFill,
                          onTap: () => onSelected(index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTab extends StatelessWidget {
  const _GlassTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.foreground,
    required this.fill,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color foreground;
  final Color fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? fill : Colors.transparent,
          borderRadius: radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: foreground, size: 21),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
