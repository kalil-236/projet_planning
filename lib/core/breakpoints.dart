/// Disposition de l'application selon la largeur disponible (section 9.1).
enum ShellLayout {
  mobile,
  tablet,
  desktop;

  static const double tabletMinWidth = 600;
  static const double desktopMinWidth = 1024;

  static ShellLayout forWidth(double width) {
    if (width < tabletMinWidth) return ShellLayout.mobile;
    if (width < desktopMinWidth) return ShellLayout.tablet;
    return ShellLayout.desktop;
  }
}
