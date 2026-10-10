import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

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

class _AlreadyPremium extends StatelessWidget {
  const _AlreadyPremium();

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
            Text(l10n.premiumActive, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _OfferingsView extends ConsumerStatefulWidget {
  const _OfferingsView();

  @override
  ConsumerState<_OfferingsView> createState() => _OfferingsViewState();
}

class _OfferingsViewState extends ConsumerState<_OfferingsView> {
  Offering? _offering;
  bool _isLoading = true;
  String? _loadError;
  String? _purchasingPackageId;
  bool _isRestoring = false;
  String? _actionMessage;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
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

  Future<void> _purchase(Package package) async {
    final l10n = context.l10n;
    setState(() {
      _purchasingPackageId = package.identifier;
      _actionMessage = null;
    });
    try {
      await Purchases.purchase(PurchaseParams.package(package));
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
    final packages = [offering.monthly, offering.annual, offering.lifetime].whereType<Package>().toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.premiumTagline, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        for (final package in packages) ...[
          _PackageCard(
            package: package,
            isPurchasing: _purchasingPackageId == package.identifier,
            onTap: _purchasingPackageId != null ? null : () => _purchase(package),
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

class _PackageCard extends StatelessWidget {
  final Package package;
  final bool isPurchasing;
  final VoidCallback? onTap;

  const _PackageCard({required this.package, required this.isPurchasing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final product = package.storeProduct;
    final intro = product.introductoryPrice;
    final isFreeTrial = intro != null && intro.price == 0;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
        title: Text(product.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: isFreeTrial
            ? Text(l10n.freeTrialThen(intro.periodNumberOfUnits, product.priceString))
            : Text(product.priceString),
        trailing: isPurchasing
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
