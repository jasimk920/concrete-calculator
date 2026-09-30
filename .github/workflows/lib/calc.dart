import 'dart:math' as math;

enum UnitSystem { metric, imperial }

const double _ft3PerM3 = 35.3147;
const double _yd3PerM3 = 1.307951;

class ConcreteResult {
  final double m3;
  const ConcreteResult(this.m3);

  double get yd3 => m3 * _yd3PerM3;
  double get ft3 => m3 * _ft3PerM3;
}

class BagSize {
  final String label;
  final double yieldM3;
  const BagSize(this.label, this.yieldM3);

  int bagsFor(double m3) => (m3 / yieldM3).ceil();
}

/// Approximate yields of pre-mixed concrete bags. Always check the bag label.
const List<BagSize> imperialBags = [
  BagSize('80 lb bag', 0.6 / _ft3PerM3),
  BagSize('60 lb bag', 0.45 / _ft3PerM3),
  BagSize('50 lb bag', 0.375 / _ft3PerM3),
];

const List<BagSize> metricBags = [
  BagSize('40 kg bag', 0.0187),
  BagSize('25 kg bag', 0.0117),
];

class ConcreteCalc {
  /// Slab or footing.
  /// Metric: length and width in metres, thickness in centimetres.
  /// Imperial: length and width in feet, thickness in inches.
  static ConcreteResult slab({
    required UnitSystem unit,
    required double length,
    required double width,
    required double thickness,
    required double wastePercent,
  }) {
    final double m3 = unit == UnitSystem.metric
        ? length * width * (thickness / 100)
        : (length * width * (thickness / 12)) / _ft3PerM3;
    return ConcreteResult(m3 * (1 + wastePercent / 100));
  }

  /// Round column.
  /// Metric: diameter in centimetres, height in metres.
  /// Imperial: diameter in inches, height in feet.
  static ConcreteResult column({
    required UnitSystem unit,
    required double diameter,
    required double height,
    required int quantity,
    required double wastePercent,
  }) {
    final double m3 = unit == UnitSystem.metric
        ? math.pi * math.pow(diameter / 200, 2) * height * quantity
        : (math.pi * math.pow(diameter / 24, 2) * height * quantity) /
            _ft3PerM3;
    return ConcreteResult(m3 * (1 + wastePercent / 100));
  }
}
