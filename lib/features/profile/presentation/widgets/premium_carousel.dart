import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:camp_meet/core/services/payment_service.dart';

class PremiumCarousel extends StatefulWidget {
  const PremiumCarousel({super.key});

  @override
  State<PremiumCarousel> createState() => _PremiumCarouselState();
}

class _PremiumCarouselState extends State<PremiumCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  final _paymentService = PaymentService();

  // Preise: Fallback-Werte
  String _premiumMonthly = '3,99 €';
  String _premiumAnnual = '29,99 €';

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPrices() async {
    if (!mounted) return;
    setState(() {
      final monthlyProduct =
          _paymentService.getProductDetails(ProductIds.premiumMonthly);
      final annualProduct =
          _paymentService.getProductDetails(ProductIds.premiumAnnual);

      _premiumMonthly = monthlyProduct?.price ?? _premiumMonthly;
      _premiumAnnual = annualProduct?.price ?? _premiumAnnual;
    });
  }

  List<Map<String, dynamic>> get _plans => [
        {
          'title': 'Premium Monthly',
          'subtitle': 'Monatlich flexibel',
          'price': _premiumMonthly,
          'color': const Color(0xFF9B30FF),
          'features': [
            'Unbegrenzte Likes',
            '5 Super-Likes täglich',
            '1 Boost pro Monat',
            'Keine Werbung',
            'Erweiterte Filter',
            'Lese-Bestätigungen im Chat',
            'Reisepass (Ort ändern)',
          ],
          'productId': ProductIds.premiumMonthly,
          'duration': 'pro Monat',
          'saving': null,
        },
        {
          'title': 'Premium Annual',
          'subtitle': 'Sparen Sie 58%',
          'price': _premiumAnnual,
          'color': const Color(0xFFFF2D9B),
          'features': [
            'Unbegrenzte Likes',
            '5 Super-Likes täglich',
            '5 Boosts pro Monat',
            'Keine Werbung',
            'Erweiterte Filter',
            'Lese-Bestätigungen im Chat',
            'Reisepass (Ort ändern)',
            'Exklusiver Premium-Badge',
          ],
          'productId': ProductIds.premiumAnnual,
          'duration': 'pro Jahr',
          'saving': '58% sparen',
        },
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 440,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _plans.length,
            itemBuilder: (context, index) {
              final plan = _plans[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double scale = 1.0;
                  if (_pageController.position.haveDimensions) {
                    final diff = _pageController.page! - index;
                    scale = (1 - (diff.abs() * 0.08)).clamp(0.85, 1.0);
                  }
                  return Transform.scale(scale: scale, child: child);
                },
                child: _PremiumPlanCard(
                  title: plan['title'],
                  subtitle: plan['subtitle'],
                  price: plan['price'],
                  color: plan['color'],
                  features: List<String>.from(plan['features']),
                  productId: plan['productId'],
                  duration: plan['duration'],
                  saving: plan['saving'],
                  paymentService: _paymentService,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _plans.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentPage == index
                    ? (_plans[index]['color'] as Color)
                    : context.fgA(0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan Card
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumPlanCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String price;
  final Color color;
  final List<String> features;
  final String productId;
  final String duration;
  final String? saving;
  final PaymentService paymentService;

  const _PremiumPlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.color,
    required this.features,
    required this.productId,
    required this.duration,
    this.saving,
    required this.paymentService,
  });

  @override
  State<_PremiumPlanCard> createState() => _PremiumPlanCardState();
}

class _PremiumPlanCardState extends State<_PremiumPlanCard> {
  bool _isLoading = false;

  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);

    final result =
        await widget.paymentService.purchaseSubscription(widget.productId);

    if (!mounted) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = false);

    if (result.success) {
      // Aktualisiere Premium Status
      await widget.paymentService.setPremium(true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '${widget.title} aktiviert',
            style: TextStyle(),
          ),
          backgroundColor: const Color(0xFF9B30FF),
          duration: const Duration(seconds: 3),
        ));
      }
    } else if (!result.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Kauf fehlgeschlagen: ${result.error ?? "Unbekannter Fehler"}',
          style: TextStyle(),
        ),
        backgroundColor: const Color(0xFFFF4B6E),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBestValue = widget.saving != null;
    final fg = isBestValue ? Colors.white : context.fg;
    final muted = isBestValue ? Colors.white70 : context.fgA(0.6);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      decoration: BoxDecoration(
        gradient: isBestValue
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF2D9B),
                  Color(0xFF9B30FF),
                  Color(0xFF5B2BF0)
                ],
              )
            : null,
        color: isBestValue ? null : context.card,
        borderRadius: BorderRadius.circular(20),
        border: isBestValue
            ? null
            : Border.all(
                color: widget.color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (isBestValue)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.saving!,
                  style: const TextStyle(
                    color: Color(0xFF9B30FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            if (isBestValue) const SizedBox(height: 12),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isBestValue ? Colors.white : widget.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(widget.subtitle, style: TextStyle(color: muted, fontSize: 13)),
            const SizedBox(height: 12),
            Text(
              widget.price,
              style: TextStyle(
                color: fg,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(widget.duration, style: TextStyle(color: muted, fontSize: 13)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: widget.features
                      .map((feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.checkmark_alt,
                                    size: 18,
                                    color: isBestValue
                                        ? Colors.white
                                        : widget.color),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: TextStyle(color: fg, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handlePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBestValue ? Colors.white : widget.color,
                  foregroundColor:
                      isBestValue ? const Color(0xFF9B30FF) : Colors.white,
                  disabledBackgroundColor:
                      (isBestValue ? Colors.white : widget.color)
                          .withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isBestValue
                              ? const Color(0xFF9B30FF)
                              : Colors.white,
                        ),
                      )
                    : const Text(
                        'Jetzt abonnieren',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
