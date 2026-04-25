import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/currency_service.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final _amountController = TextEditingController();
  String _selectedCurrency = 'USD';
  double? _convertedAmount;
  Map<String, double> _rates = {};
  bool _isLoading = false;
  bool _isFetching = false;
  String? _error;
  double? _lastRate;

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥', 'flag': '🇯🇵'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£', 'flag': '🇬🇧'},
    {
      'code': 'SGD',
      'name': 'Singapore Dollar',
      'symbol': 'S\$',
      'flag': '🇸🇬'
    },
    {
      'code': 'MYR',
      'name': 'Malaysian Ringgit',
      'symbol': 'RM',
      'flag': '🇲🇾'
    },
    {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': '﷼', 'flag': '🇸🇦'},
  ];

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(amount)}';
  }

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchRates() async {
    setState(() {
      _isFetching = true;
      _error = null;
    });
    try {
      final rates = await CurrencyService.fetchRates();
      setState(() {
        _rates = rates;
        _isFetching = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat kurs. Periksa koneksi internet Anda.';
        _isFetching = false;
      });
    }
  }

  void _convert() {
    if (_amountController.text.isEmpty) return;
    final amount = double.tryParse(
        _amountController.text.replaceAll('.', '').replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Masukkan nominal yang valid'),
          backgroundColor: AppTheme.expenseColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final rate = _rates[_selectedCurrency];
    if (rate == null) return;

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _convertedAmount =
              CurrencyService.convert(amountIDR: amount, rate: rate);
          _lastRate = rate;
          _isLoading = false;
        });
      }
    });
  }

  String _formatConverted(double amount) {
    if (_selectedCurrency == 'JPY') {
      return NumberFormat('#,###').format(amount.round());
    }
    return amount.toStringAsFixed(2);
  }

  Map<String, String> get _selectedCurrencyData =>
      _currencies.firstWhere((c) => c['code'] == _selectedCurrency,
          orElse: () => _currencies[0]);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final totalExpense = provider.totalExpense;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Konversi Mata Uang'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _fetchRates,
            icon: _isFetching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded,
                    color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Rate Status
            if (_isFetching)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Memuat kurs real-time...',
                      style: TextStyle(fontSize: 13, color: AppTheme.primary),
                    ),
                  ],
                ),
              )
            else if (_error != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.expenseColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 16, color: AppTheme.expenseColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.expenseColor),
                      ),
                    ),
                    GestureDetector(
                      onTap: _fetchRates,
                      child: const Text(
                        'Coba lagi',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.incomeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: AppTheme.incomeColor),
                    SizedBox(width: 6),
                    Text(
                      'Kurs real-time berhasil dimuat',
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.incomeColor),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Quick convert from total expense
            if (totalExpense > 0)
              GestureDetector(
                onTap: () {
                  _amountController.text = totalExpense.toInt().toString();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.08),
                        AppTheme.primaryLight.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.2), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            size: 18, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Konversi Total Pengeluaran',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatCurrency(totalExpense),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            if (totalExpense > 0) const SizedBox(height: 20),

            // Input Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jumlah Rupiah (IDR)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Mata Uang Tujuan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.silverLight),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCurrency,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.expand_more_rounded,
                          color: AppTheme.textSecondary),
                      items: _currencies.map((c) {
                        return DropdownMenuItem(
                          value: c['code'],
                          child: Row(
                            children: [
                              Text(
                                c['flag']!,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    c['code']!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    c['name']!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textHint,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (_rates[c['code']] != null)
                                Text(
                                  '1 IDR = ${_rates[c['code']]!.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textHint,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCurrency = val!;
                          _convertedAmount = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed:
                        (_isFetching || _rates.isEmpty) ? null : _convert,
                    icon: const Icon(Icons.currency_exchange_rounded, size: 18),
                    label: const Text('Konversi Sekarang'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Result Card
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: _convertedAmount != null
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF37474F),
                          Color(0xFF546E7A),
                        ],
                      )
                    : null,
                color: _convertedAmount == null ? AppTheme.surface : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _convertedAmount != null
                      ? Colors.transparent
                      : AppTheme.divider,
                ),
                boxShadow: _convertedAmount != null
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Column(
                      children: [
                        Text(
                          'Hasil Konversi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _convertedAmount != null
                                ? Colors.white60
                                : AppTheme.textHint,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_convertedAmount != null) ...[
                          Text(
                            '${_selectedCurrencyData['symbol']} ${_formatConverted(_convertedAmount!)}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedCurrency,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_lastRate != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '1 IDR = ${_lastRate!.toStringAsFixed(6)} $_selectedCurrency',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ] else
                          Text(
                            '0.00 $_selectedCurrency',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.silver,
                            ),
                          ),
                      ],
                    ),
            ),

            // Currency quick rates
            if (_rates.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kurs Hari Ini (dari IDR)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...(_currencies.take(5).map((c) {
                final rate = _rates[c['code']];
                if (rate == null) return const SizedBox();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      Text(c['flag']!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['code']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            c['name']!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${c['symbol']} ${rate.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
