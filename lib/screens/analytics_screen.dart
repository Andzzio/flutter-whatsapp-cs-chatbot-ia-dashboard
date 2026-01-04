import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'week';
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _trends;
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // Cargar estadísticas y tendencias en paralelo
      final results = await Future.wait([
        _apiService.getAnalyticsStats(chatProvider.apiToken, _selectedPeriod),
        _apiService.getAnalyticsTrends(
          chatProvider.apiToken,
          _selectedPeriod,
          'sales',
        ),
      ]);

      setState(() {
        _stats = results[0];
        _trends = results[1];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando estadísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            icon: const Icon(Icons.calendar_today),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'today', child: Text('Hoy')),
              const PopupMenuItem(value: 'week', child: Text('Esta Semana')),
              const PopupMenuItem(value: 'month', child: Text('Este Mes')),
              const PopupMenuItem(value: 'year', child: Text('Este Año')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Determinar si es desktop o mobile
                  final isDesktop = constraints.maxWidth > 800;
                  final maxContentWidth = isDesktop ? 1200.0 : double.infinity;

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // KPIs Grid - Responsive
                            GridView.count(
                              crossAxisCount: isDesktop ? 4 : 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: isDesktop ? 1.5 : 1.3,
                              children: [
                                _StatCard(
                                  title: 'Conversaciones',
                                  value:
                                      _stats?['total_conversations']
                                          ?.toString() ??
                                      '0',
                                  icon: Icons.chat_bubble_outline,
                                  color: Colors.blue,
                                ),
                                _StatCard(
                                  title: 'Pendientes',
                                  value:
                                      _stats?['pending_orders']?.toString() ??
                                      '0',
                                  icon: Icons.shopping_cart,
                                  color: Colors.orange,
                                ),
                                _StatCard(
                                  title: 'No Leídos',
                                  value:
                                      _stats?['unread_messages']?.toString() ??
                                      '0',
                                  icon: Icons.mark_email_unread,
                                  color: Colors.red,
                                ),
                                _StatCard(
                                  title: 'Online',
                                  value:
                                      _stats?['online_now']?.toString() ?? '0',
                                  icon: Icons.radio_button_checked,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Chart section
                            const Text(
                              'Tendencia de Ventas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (_trends != null && _trends!['values'] != null)
                              _SalesTrendChart(
                                labels: List<String>.from(
                                  _trends!['labels'] ?? [],
                                ),
                                values: List<dynamic>.from(
                                  _trends!['values'] ?? [],
                                ).map((e) => (e as num).toDouble()).toList(),
                                period: _selectedPeriod,
                              )
                            else
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bar_chart_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No hay datos para mostrar',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesTrendChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final String period;

  const _SalesTrendChart({
    required this.labels,
    required this.values,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    // Encontrar el valor máximo para escalar el gráfico
    final maxValue = values.isEmpty
        ? 100.0
        : values.reduce((a, b) => a > b ? a : b);
    final adjustedMax = maxValue * 1.2; // 20% de padding superior

    // Asegurar que adjustedMax nunca sea 0 para evitar errores
    final safeMax = adjustedMax > 0 ? adjustedMax : 100.0;
    final safeInterval = safeMax / 5; // Siempre será > 0

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: ajustar altura y tamaños según ancho
        final isDesktop = constraints.maxWidth > 800;
        final chartHeight = isDesktop ? 300.0 : 200.0;
        final fontSize = isDesktop ? 12.0 : 10.0;
        final barWidth = isDesktop ? 20.0 : 16.0;
        final reservedSize = isDesktop ? 50.0 : 40.0;

        return Container(
          height: chartHeight,
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: safeMax,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      'S/${rod.toY.toStringAsFixed(2)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: fontSize,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: reservedSize,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        'S/${value.toInt()}',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: safeInterval,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                values.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: values[index],
                      color: Colors.blue,
                      width: barWidth,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
