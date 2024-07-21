import 'package:flutter/material.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) builder;

  const ResponsiveBuilder({required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, constraints);
      },
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200 && largeDesktop != null) {
          return largeDesktop!;
        } else if (constraints.maxWidth >= 800 && desktop != null) {
          return desktop!;
        } else if (constraints.maxWidth >= 600 && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;
  final EdgeInsets? padding;
  final ScrollDirection scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool primary;
  final ScrollPhysics? physics;

  const ResponsiveGrid({
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary = true,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        int columns;
        
        if (constraints.maxWidth >= 800) {
          columns = desktopColumns;
        } else if (constraints.maxWidth >= 600) {
          columns = tabletColumns;
        } else {
          columns = mobileColumns;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          padding: padding,
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          children: children,
        );
      },
    );
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final AlignmentGeometry alignment;
  final double? width;
  final double? height;

  const ResponsiveContainer({
    required this.child,
    this.maxWidth = 1200,
    this.padding,
    this.alignment = Alignment.center,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        double containerWidth = width ?? constraints.maxWidth;
        
        if (maxWidth != null && containerWidth > maxWidth!) {
          containerWidth = maxWidth!;
        }

        return Container(
          width: containerWidth,
          height: height,
          alignment: alignment,
          padding: padding,
          child: child,
        );
      },
    );
  }
}

class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? elevation;
  final Color? color;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const AdaptiveCard({
    required this.child,
    this.margin,
    this.padding,
    this.elevation,
    this.color,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final cardMargin = margin ?? (isMobile ? EdgeInsets.all(8) : EdgeInsets.all(16));
        final cardPadding = padding ?? (isMobile ? EdgeInsets.all(12) : EdgeInsets.all(16));
        final cardElevation = elevation ?? (isMobile ? 2.0 : 4.0);
        final cardRadius = borderRadius ?? BorderRadius.circular(isMobile ? 8.0 : 12.0);

        Widget card = Card(
          margin: cardMargin,
          elevation: cardElevation,
          color: color,
          shape: RoundedRectangleBorder(borderRadius: cardRadius),
          child: Padding(
            padding: cardPadding,
            child: child,
          ),
        );

        if (onTap != null) {
          card = InkWell(
            onTap: onTap,
            borderRadius: cardRadius,
            child: card,
          );
        }

        return card;
      },
    );
  }
}

class AdaptiveButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Widget? icon;
  final bool isFullWidth;
  final ButtonStyle? style;
  final bool isLoading;

  const AdaptiveButton({
    required this.text,
    required this.onPressed,
    this.icon,
    this.isFullWidth = false,
    this.style,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final buttonWidth = isFullWidth ? double.infinity : null;

        Widget button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      SizedBox(width: isMobile ? 8 : 12),
                    ],
                    Text(text),
                  ],
                ),
        );

        if (isFullWidth) {
          button = SizedBox(width: buttonWidth, child: button);
        }

        return button;
      },
    );
  }
}

class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AdaptiveAppBar({
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final appBarElevation = elevation ?? (isMobile ? 0.0 : 4.0);

        return AppBar(
          title: Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: actions,
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          flexibleSpace: flexibleSpace,
          bottom: bottom,
          elevation: appBarElevation,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        );
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class AdaptiveNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final NavigationRailLabelType? labelType;
  final bool? extended;

  const AdaptiveNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.labelType,
    this.extended,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          return BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onDestinationSelected,
            type: BottomNavigationBarType.fixed,
            items: destinations.map((destination) {
              return BottomNavigationBarItem(
                icon: destination.icon,
                label: destination.label,
              );
            }).toList(),
          );
        } else {
          return NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            extended: extended ?? constraints.maxWidth > 800,
            labelType: labelType ?? NavigationRailLabelType.all,
            destinations: destinations,
          );
        }
      },
    );
  }
}

class AdaptiveDrawer extends StatelessWidget {
  final Widget child;
  final double? width;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool semanticLabel;

  const AdaptiveDrawer({
    required this.child,
    this.width,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.semanticLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final drawerWidth = width ?? (isMobile ? 280.0 : 320.0);
        final drawerPadding = padding ?? (isMobile ? EdgeInsets.all(16) : EdgeInsets.all(24));

        return Drawer(
          width: drawerWidth,
          child: Container(
            padding: drawerPadding,
            color: backgroundColor,
            child: child,
          ),
          backgroundColor: backgroundColor,
          elevation: elevation,
          shape: shape,
          semanticLabel: semanticLabel ? 'Navigation drawer' : null,
        );
      },
    );
  }
}

class AdaptiveDialog extends StatelessWidget {
  final String title;
  final String? content;
  final List<Widget> actions;
  final Widget? child;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  final bool useSafeArea;
  final bool useRootNavigator;

  const AdaptiveDialog({
    required this.title,
    this.content,
    required this.actions,
    this.child,
    this.barrierDismissible = true,
    this.barrierColor,
    this.barrierLabel,
    this.useSafeArea = true,
    this.useRootNavigator = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final dialogPadding = isMobile ? EdgeInsets.all(16) : EdgeInsets.all(24);
        final actionsPadding = isMobile ? EdgeInsets.symmetric(horizontal: 8, vertical: 8) : EdgeInsets.symmetric(horizontal: 16, vertical: 16);

        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: child ?? (content != null ? Text(content!) : null),
          actions: actions,
          actionsPadding: actionsPadding,
          contentPadding: dialogPadding,
          insetPadding: isMobile ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          barrierDismissible: barrierDismissible,
          barrierColor: barrierColor,
          barrierLabel: barrierLabel,
          scrollable: true,
        );
      },
    );
  }
}

class AdaptiveSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? flexibleSpace;
  final Widget? bottom;
  final double? expandedHeight;
  final bool pinned;
  final bool floating;
  final bool snap;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AdaptiveSliverAppBar({
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.flexibleSpace,
    this.bottom,
    this.expandedHeight,
    this.pinned = false,
    this.floating = false,
    this.snap = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final appBarHeight = expandedHeight ?? (isMobile ? 200.0 : 250.0);

        return SliverAppBar(
          title: Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: actions,
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          flexibleSpace: flexibleSpace,
          bottom: bottom,
          expandedHeight: appBarHeight,
          pinned: pinned,
          floating: floating,
          snap: snap,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        );
      },
    );
  }
}

class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;
  final TextDirection? direction;
  final VerticalDirection verticalDirection;

  const ResponsiveWrap({
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.direction,
    this.verticalDirection = VerticalDirection.down,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final wrapSpacing = isMobile ? spacing * 0.8 : spacing;
        final wrapRunSpacing = isMobile ? runSpacing * 0.8 : runSpacing;

        return Wrap(
          spacing: wrapSpacing,
          runSpacing: wrapRunSpacing,
          alignment: alignment,
          crossAxisAlignment: crossAxisAlignment,
          direction: direction,
          verticalDirection: verticalDirection,
          children: children,
        );
      },
    );
  }
}

class BreakpointBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Breakpoint breakpoint) builder;

  const BreakpointBuilder({required this.builder});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        final breakpoint = Breakpoint.fromWidth(constraints.maxWidth);
        return builder(context, breakpoint);
      },
    );
  }
}

enum Breakpoint {
  mobile,
  tablet,
  desktop,
  largeDesktop;

  static Breakpoint fromWidth(double width) {
    if (width >= 1200) {
      return Breakpoint.largeDesktop;
    } else if (width >= 800) {
      return Breakpoint.desktop;
    } else if (width >= 600) {
      return Breakpoint.tablet;
    } else {
      return Breakpoint.mobile;
    }
  }
}
