import 'package:flutter/material.dart';

import 'ads.dart';
import 'calc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.init();
  runApp(const ConcreteApp());
}

class ConcreteApp extends StatelessWidget {
  const ConcreteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Concrete Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF546E7A),
        useMaterial3: true,
      ),
      home: const CalculatorPage(),
    );
  }
}

enum Shape { slab, column }

/// One concrete mix: ratio of cement : sand : aggregate.
class MixDesign {
  final String label;
  final double cement;
  final double sand;
  final double aggregate;
  const MixDesign(this.label, this.cement, this.sand, this.aggregate);

  String get ratio =>
      '${_part(cement)} : ${_part(sand)} : ${_part(aggregate)}';

  static String _part(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

const List<MixDesign> mixDesigns = [
  MixDesign('M15', 1, 2, 4),
  MixDesign('M20', 1, 1.5, 3),
  MixDesign('M25', 1, 1, 2),
];

/// Rough site-mix material quantities for a given volume of concrete.
class MaterialEstimate {
  final double cementBags;
  final double sandM3;
  final double aggregateM3;

  const MaterialEstimate({
    required this.cementBags,
    required this.sandM3,
    required this.aggregateM3,
  });

  factory MaterialEstimate.from(double concreteM3, MixDesign mix) {
    // Dry volume of materials needed for 1 m3 of wet concrete.
    const double dryFactor = 1.54;
    // Volume of one 50 kg cement bag (cement density about 1440 kg/m3).
    const double bagM3 = 50 / 1440;
    final double parts = mix.cement + mix.sand + mix.aggregate;
    final double dryM3 = concreteM3 * dryFactor;
    return MaterialEstimate(
      cementBags: dryM3 * mix.cement / parts / bagM3,
      sandM3: dryM3 * mix.sand / parts,
      aggregateM3: dryM3 * mix.aggregate / parts,
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  UnitSystem unit = UnitSystem.metric;
  Shape shape = Shape.slab;
  int mixIndex = 1; // M20 by default

  final length = TextEditingController();
  final width = TextEditingController();
  final thickness = TextEditingController();
  final diameter = TextEditingController();
  final height = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final waste = TextEditingController(text: '10');

  ConcreteResult? result;
  String? error;
  int calcCount = 0;

  bool get metric => unit == UnitSystem.metric;
  String get bigUnit => metric ? 'm' : 'ft';
  String get smallUnit => metric ? 'cm' : 'in';

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _calculate() {
    FocusScope.of(context).unfocus();
    final w = _num(waste) ?? 0;

    if (shape == Shape.slab) {
      final l = _num(length), wd = _num(width), t = _num(thickness);
      if (l == null || wd == null || t == null || l <= 0 || wd <= 0 || t <= 0) {
        return _fail('Please enter length, width and thickness (greater than 0).');
      }
      result = ConcreteCalc.slab(
        unit: unit,
        length: l,
        width: wd,
        thickness: t,
        wastePercent: w,
      );
    } else {
      final d = _num(diameter), h = _num(height);
      final q = int.tryParse(quantity.text.trim()) ?? 0;
      if (d == null || h == null || d <= 0 || h <= 0 || q <= 0) {
        return _fail('Please enter diameter, height and quantity (greater than 0).');
      }
      result = ConcreteCalc.column(
        unit: unit,
        diameter: d,
        height: h,
        quantity: q,
        wastePercent: w,
      );
    }

    setState(() => error = null);
    calcCount++;
    // Show a full-screen ad only after every 3rd result, never before it.
    if (calcCount % 3 == 0) AdService.instance.showInterstitial();
  }

  void _fail(String message) {
    setState(() {
      error = message;
      result = null;
    });
  }

  void _clear() {
    for (final c in [length, width, thickness, diameter, height]) {
      c.clear();
    }
    quantity.text = '1';
    waste.text = '10';
    setState(() {
      result = null;
      error = null;
    });
  }

  Widget _field(String label, TextEditingController c, {String? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  String _vol(double m3) =>
      '${m3.toStringAsFixed(2)} m³  (${(m3 * 35.3147).toStringAsFixed(1)} ft³)';

  Widget _materialsSection(BuildContext context, double concreteM3) {
    final mix = mixDesigns[mixIndex];
    final est = MaterialEstimate.from(concreteM3, mix);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Materials for site-mixed concrete',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: [
            for (int i = 0; i < mixDesigns.length; i++)
              ButtonSegment(value: i, label: Text(mixDesigns[i].label)),
          ],
          selected: {mixIndex},
          onSelectionChanged: (s) => setState(() => mixIndex = s.first),
        ),
        const SizedBox(height: 8),
        Text('Mix ratio (cement : sand : aggregate) = ${mix.ratio}'),
        const SizedBox(height: 8),
        Text('Cement: ${est.cementBags.ceil()} bags (50 kg each)'),
        Text('Sand: ${_vol(est.sandM3)}'),
        Text('Aggregate (gitti): ${_vol(est.aggregateM3)}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bags = metric ? metricBags : imperialBags;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Concrete Calculator'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.refresh),
            onPressed: _clear,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<UnitSystem>(
            segments: const [
              ButtonSegment(value: UnitSystem.metric, label: Text('Metric')),
              ButtonSegment(value: UnitSystem.imperial, label: Text('Imperial')),
            ],
            selected: {unit},
            onSelectionChanged: (s) => setState(() {
              unit = s.first;
              result = null;
            }),
          ),
          const SizedBox(height: 12),
          SegmentedButton<Shape>(
            segments: const [
              ButtonSegment(value: Shape.slab, label: Text('Slab / Footing')),
              ButtonSegment(value: Shape.column, label: Text('Round Column')),
            ],
            selected: {shape},
            onSelectionChanged: (s) => setState(() {
              shape = s.first;
              result = null;
            }),
          ),
          const SizedBox(height: 20),
          if (shape == Shape.slab) ...[
            _field('Length', length, suffix: bigUnit),
            _field('Width', width, suffix: bigUnit),
            _field('Thickness / Depth', thickness, suffix: smallUnit),
          ] else ...[
            _field('Diameter', diameter, suffix: smallUnit),
            _field('Height', height, suffix: bigUnit),
            _field('Number of columns', quantity),
          ],
          _field('Extra for waste / spillage', waste, suffix: '%'),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculate'),
          ),
          if (result != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Concrete needed',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('${result!.m3.toStringAsFixed(2)} m³',
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text('${result!.yd3.toStringAsFixed(2)} yd³'
                        '   •   ${result!.ft3.toStringAsFixed(1)} ft³'),
                    const Divider(height: 28),
                    Text('Pre-mixed bags (approx.)',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final b in bags)
                      Text('${b.label}: ${b.bagsFor(result!.m3)} bags'),
                    const Divider(height: 28),
                    _materialsSection(context, result!.m3),
                    const SizedBox(height: 12),
                    Text(
                      'Estimates only. Quantities change with material quality '
                      'and site conditions. Steel (saria), shuttering and labour '
                      'are not included. Please confirm with your engineer or '
                      'mason.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
    );
  }
}
