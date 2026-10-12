import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/env.dart';
import '../../../core/l10n_extension.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/account_page.dart';
import '../data/premium_providers.dart';
import '../data/premium_repository.dart';

class PaywallPage extends ConsumerWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.premium)),
      body: switch ((user, isPremium)) {
        (null, _) => const _SignInPrompt(),
        (_, true) => const _AlreadyPremium(),
        (_, false) => const _OfferingsView(),
      },
    );
  }
}

/// The circular tinted icon used at the top of every state this page can
/// be in (sign-in prompt, already-Premium, offerings) -- one shared visual
/// anchor rather than three slightly different bare icons.
class _HeroIcon extends StatelessWidget {
  final IconData icon;
  const _HeroIcon({this.icon = Icons.workspace_premium_rounded});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
      child: Icon(icon, size: 40, color: scheme.onPrimaryContainer),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _HeroIcon(),
            const SizedBox(height: 20),
            Text(l10n.signInToSubscribe, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountPage())),
              child: Text(l10n.signIn),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlreadyPremium extends ConsumerWidget {
  const _AlreadyPremium();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isMock = kDebugMode && ref.watch(debugMockPremiumProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _HeroIcon(icon: Icons.verified_rounded),
            const SizedBox(height: 20),
            Text(l10n.premiumActive, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            if (isMock) ...[
              const SizedBox(height: 24),
              _TestModeBanner(
                label: 'This is a simulated purchase, not a real one.',
                action: TextButton(
                  onPressed: () => ref.read(debugMockPremiumProvider.notifier).set(false),
                  child: const Text('End test: remove mock Premium'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A plain display model so the UI doesn't need a real RevenueCat
/// [Package] -- constructing one by hand would mean faking a dozen+
/// fields across [StoreProduct]/[PresentedOfferingContext] that only
/// make sense coming from an actual store response. [realPackage] is
/// null for the debug-only mock tiers below, which is how _purchase
/// decides whether to call RevenueCat at all.
class _PackageDisplay {
  final String id;
  final String title;
  final String priceString;
  // Raw numeric price (StoreProduct.price), not parsed from
  // priceString -- savingsPercent below is computed from this, never
  // from the formatted string, since that's locale/currency-formatted
  // text that isn't safe to parse back into a number.
  final double price;
  final int? freeTrialDays;
  final bool isRecommended;
  final int? savingsPercent;
  final Package? realPackage;

  const _PackageDisplay({
    required this.id,
    required this.title,
    required this.priceString,
    required this.price,
    this.freeTrialDays,
    this.isRecommended = false,
    this.savingsPercent,
    this.realPackage,
  });

  factory _PackageDisplay.fromPackage(Package package, {bool isRecommended = false, int? savingsPercent}) {
    final product = package.storeProduct;
    final intro = product.introductoryPrice;
    final isFreeTrial = intro != null && intro.price == 0;
    return _PackageDisplay(
      id: package.identifier,
      title: product.title,
      priceString: product.priceString,
      price: product.price,
      freeTrialDays: isFreeTrial ? intro.periodNumberOfUnits : null,
      isRecommended: isRecommended,
      savingsPercent: savingsPercent,
      realPackage: package,
    );
  }
}

/// How much cheaper [comparedPrice] is than paying [basePrice] for the
/// same stretch of time it covers (e.g. 12x the monthly price for an
/// annual plan) -- null when there's nothing to compare against, or the
/// "discount" would be zero or negative (a monthly price that didn't
/// actually save anything isn't worth a badge).
int? _savingsPercent({required double basePrice, required int baseMultiplier, required double comparedPrice}) {
  final baseTotal = basePrice * baseMultiplier;
  if (baseTotal <= 0) return null;
  final percent = ((baseTotal - comparedPrice) / baseTotal * 100).round();
  return percent > 0 ? percent : null;
}

final _mockMonthlyPrice = 29.0;
final _mockAnnualPrice = 290.0;
final _mockPackages = [
  _PackageDisplay(id: 'mock_monthly', title: 'Monthly', priceString: '₹29/month', price: _mockMonthlyPrice, freeTrialDays: 7),
  _PackageDisplay(
    id: 'mock_annual',
    title: 'Annual',
    priceString: '₹290/year',
    price: _mockAnnualPrice,
    isRecommended: true,
    savingsPercent: _savingsPercent(basePrice: _mockMonthlyPrice, baseMultiplier: 12, comparedPrice: _mockAnnualPrice),
  ),
  const _PackageDisplay(id: 'mock_lifetime', title: 'Lifetime', priceString: '₹699 one-time', price: 699),
];

class _OfferingsView extends ConsumerStatefulWidget {
  const _OfferingsView();

  @override
  ConsumerState<_OfferingsView> createState() => _OfferingsViewState();
}

class _OfferingsViewState extends ConsumerState<_OfferingsView> {
  // Debug builds with no RevenueCat key yet (the real state until a
  // RevenueCat project + Play Console products exist) show these mock
  // tiers instead of erroring, so the paywall can be clicked through
  // end-to-end -- see debugMockPremiumProvider's doc comment for why
  // this can't leak into a release build.
  bool get _useMockOfferings => kDebugMode && !Env.hasRevenueCat;

  Offering? _offering;
  bool _isLoading = true;
  String? _loadError;
  String? _purchasingPackageId;
  bool _isRestoring = false;
  String? _actionMessage;

  @override
  void initState() {
    super.initState();
    if (_useMockOfferings) {
      _isLoading = false;
    } else {
      _loadOfferings();
    }
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final offerings = await Purchases.getOfferings();
      if (mounted) setState(() => _offering = offerings.current);
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _purchase(_PackageDisplay display) async {
    final l10n = context.l10n;
    setState(() {
      _purchasingPackageId = display.id;
      _actionMessage = null;
    });

    if (display.realPackage == null) {
      // Mock purchase: no network, no RevenueCat -- just a short delay
      // so the loading state reads as real, then flip the local flag.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        ref.read(debugMockPremiumProvider.notifier).set(true);
        setState(() => _purchasingPackageId = null);
      }
      return;
    }

    try {
      await Purchases.purchase(PurchaseParams.package(display.realPackage!));
      if (mounted) setState(() => _actionMessage = l10n.purchaseSuccessful);
    } on PlatformException catch (error) {
      final cancelled = PurchasesErrorHelper.getErrorCode(error) == PurchasesErrorCode.purchaseCancelledError;
      if (mounted && !cancelled) setState(() => _actionMessage = l10n.purchaseError);
    } finally {
      if (mounted) setState(() => _purchasingPackageId = null);
    }
  }

  Future<void> _restore() async {
    final l10n = context.l10n;
    setState(() {
      _isRestoring = true;
      _actionMessage = null;
    });
    try {
      final info = await Purchases.restorePurchases();
      final restored = info.entitlements.active.containsKey(premiumEntitlementId);
      if (mounted) setState(() => _actionMessage = restored ? l10n.restoreSuccessful : l10n.restoreNoPurchasesFound);
    } catch (_) {
      if (mounted) setState(() => _actionMessage = l10n.purchaseError);
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_useMockOfferings) {
      return _buildList(context, _mockPackages, showTestBanner: true);
    }

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_loadError != null || _offering == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.premiumNotAvailable, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _loadOfferings, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }

    final offering = _offering!;
    final monthlyPackage = offering.monthly;
    final annualPackage = offering.annual;
    final annualSavings = (monthlyPackage != null && annualPackage != null)
        ? _savingsPercent(
            basePrice: monthlyPackage.storeProduct.price,
            baseMultiplier: 12,
            comparedPrice: annualPackage.storeProduct.price,
          )
        : null;

    final displays = <_PackageDisplay>[
      if (monthlyPackage != null) _PackageDisplay.fromPackage(monthlyPackage),
      if (annualPackage != null)
        _PackageDisplay.fromPackage(annualPackage, isRecommended: true, savingsPercent: annualSavings),
      if (offering.lifetime case final lifetimePackage?) _PackageDisplay.fromPackage(lifetimePackage),
    ];
    return _buildList(context, displays, showTestBanner: false);
  }

  Widget _buildList(BuildContext context, List<_PackageDisplay> displays, {required bool showTestBanner}) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (showTestBanner) ...[
          const _TestModeBanner(
            label: 'No RevenueCat project yet -- these are fake tiers for '
                'trying out the paywall. "Purchasing" one just flips a local '
                'flag, no real payment happens.',
          ),
          const SizedBox(height: 16),
        ],
        Center(
          child: Column(
            children: [
              const _HeroIcon(),
              const SizedBox(height: 16),
              Text(
                l10n.premiumHeadline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _FeatureRow(
          icon: Icons.sync_rounded,
          title: l10n.premiumFeatureSyncTitle,
          description: l10n.premiumTagline,
        ),
        _FeatureRow(
          icon: Icons.calendar_month_rounded,
          title: l10n.readingPlans,
          description: l10n.premiumFeatureReadingPlansDescription,
        ),
        _FeatureRow(
          icon: Icons.notifications_active_rounded,
          title: l10n.premiumFeatureNotificationsTitle,
          description: l10n.premiumFeatureNotificationsDescription,
        ),
        const SizedBox(height: 12),
        for (final display in displays) ...[
          _PackageCard(
            display: display,
            isPurchasing: _purchasingPackageId == display.id,
            onTap: _purchasingPackageId != null ? null : () => _purchase(display),
          ),
          const SizedBox(height: 12),
        ],
        if (_actionMessage != null) ...[
          const SizedBox(height: 8),
          Text(_actionMessage!, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _isRestoring ? null : _restore,
            child: _isRestoring
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.restorePurchases),
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _FeatureRow({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: scheme.secondaryContainer, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: scheme.onSecondaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TestModeBanner extends StatelessWidget {
  final String label;
  final Widget? action;

  const _TestModeBanner({required this.label, this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_rounded, size: 18, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Text(
                'TEST MODE',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onErrorContainer),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: scheme.onErrorContainer)),
          ?action,
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color onColor;
  const _Badge({required this.label, required this.color, required this.onColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(color: onColor, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.3),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final _PackageDisplay display;
  final bool isPurchasing;
  final VoidCallback? onTap;

  const _PackageCard({required this.display, required this.isPurchasing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final freeTrialDays = display.freeTrialDays;
    final recommended = display.isRecommended;
    final savingsPercent = display.savingsPercent;

    return Card(
      margin: EdgeInsets.zero,
      // A flat alphaBlend against the theme's own card color, not a
      // runtime-transparent overlay -- predictable regardless of
      // what's behind it, and subtle enough not to fight the app's
      // generally muted palette.
      color: recommended ? Color.alphaBlend(scheme.primary.withValues(alpha: 0.08), scheme.surfaceContainerLow) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: recommended ? scheme.primary : Colors.transparent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recommended || savingsPercent != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  if (recommended) _Badge(label: l10n.bestValue, color: scheme.primary, onColor: scheme.onPrimary),
                  if (recommended && savingsPercent != null) const SizedBox(width: 8),
                  if (savingsPercent != null)
                    _Badge(
                      label: l10n.saveBadge(savingsPercent),
                      color: scheme.secondaryContainer,
                      onColor: scheme.onSecondaryContainer,
                    ),
                ],
              ),
            ),
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            onTap: onTap,
            title: Text(display.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: freeTrialDays != null
                ? Text(l10n.freeTrialThen(freeTrialDays, display.priceString))
                : Text(display.priceString),
            trailing: isPurchasing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
