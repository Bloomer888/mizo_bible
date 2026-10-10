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

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded, size: 48, color: scheme.primary),
            const SizedBox(height: 16),
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
    final scheme = Theme.of(context).colorScheme;
    final isMock = kDebugMode && ref.watch(debugMockPremiumProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded, size: 48, color: scheme.primary),
            const SizedBox(height: 16),
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
  final int? freeTrialDays;
  final Package? realPackage;

  const _PackageDisplay({
    required this.id,
    required this.title,
    required this.priceString,
    this.freeTrialDays,
    this.realPackage,
  });

  factory _PackageDisplay.fromPackage(Package package) {
    final product = package.storeProduct;
    final intro = product.introductoryPrice;
    final isFreeTrial = intro != null && intro.price == 0;
    return _PackageDisplay(
      id: package.identifier,
      title: product.title,
      priceString: product.priceString,
      freeTrialDays: isFreeTrial ? intro.periodNumberOfUnits : null,
      realPackage: package,
    );
  }
}

const _mockPackages = [
  _PackageDisplay(id: 'mock_monthly', title: 'Monthly', priceString: '₹29/month', freeTrialDays: 7),
  _PackageDisplay(id: 'mock_annual', title: 'Annual', priceString: '₹290/year'),
  _PackageDisplay(id: 'mock_lifetime', title: 'Lifetime', priceString: '₹699 one-time'),
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
    final displays = [offering.monthly, offering.annual, offering.lifetime]
        .whereType<Package>()
        .map(_PackageDisplay.fromPackage)
        .toList();
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
        Text(l10n.premiumTagline, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
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

class _PackageCard extends StatelessWidget {
  final _PackageDisplay display;
  final bool isPurchasing;
  final VoidCallback? onTap;

  const _PackageCard({required this.display, required this.isPurchasing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final freeTrialDays = display.freeTrialDays;

    return Card(
      child: ListTile(
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
    );
  }
}
