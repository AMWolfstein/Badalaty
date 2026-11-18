import 'package:material_ui/material_ui.dart';

ThemeData badalatyTheme(Brightness brightness) {
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
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarThemeData(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 25,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: panel,
      surfaceTintColor: Colors.transparent,
      elevation: 1.5,
      shadowColor: const Color(0x22264D77),
      margin: const EdgeInsets.only(bottom: 8),
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
        color: scheme.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      subtitleTextStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 12,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      minLeadingWidth: 34,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
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

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;

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
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: bottomNavigationBar != null,
          appBar: appBar,
          body: body,
          bottomNavigationBar: bottomNavigationBar,
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
    this.isBalance = true,
    super.key,
  });

  final String label;
  final String value;
  final Widget? detail;
  final bool isBalance;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(25);
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
                  style: const TextStyle(
                    color: Color(0xFFD5ECFF),
                    fontSize: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(label),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isBalance ? 33 : 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
