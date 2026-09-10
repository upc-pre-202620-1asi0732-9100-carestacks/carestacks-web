import 'package:flutter/material.dart';

/// Celda de [CareGrid]. [span] es cuantas columnas ocupa.
class CareGridItem {
  const CareGridItem({required this.child, this.span = 1});

  final Widget child;
  final int span;
}

/// Grilla fluida de ancho fijo por columna. Reflota a la siguiente linea
/// cuando no entra, sin dependencias externas.
class CareGrid extends StatelessWidget {
  const CareGrid({
    super.key,
    required this.columns,
    required this.items,
    this.spacing = 20,
    this.runSpacing = 20,
  });

  final int columns;
  final List<CareGridItem> items;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int index = 0; index < items.length; index++) ...[
            if (index > 0) SizedBox(height: runSpacing),
            items[index].child,
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double unit =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final item in items)
              SizedBox(
                width: _widthFor(item.span, unit) - 0.5,
                child: item.child,
              ),
          ],
        );
      },
    );
  }

  double _widthFor(int span, double unit) {
    final int clamped = span.clamp(1, columns);
    return unit * clamped + spacing * (clamped - 1);
  }
}
