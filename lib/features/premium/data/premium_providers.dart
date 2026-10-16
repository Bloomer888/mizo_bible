import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env.dart';
import '../../auth/data/auth_repository.dart';
import 'premium_repository.dart';

/// Debug-only override so Premium can be exercised end-to-end (paywall,
/// sync unlocking, etc.) before a real RevenueCat project + Play Console
/// products exist. isPremiumProvider below only ever reads this behind a
/// `kDebugMode` check, which the Dart compiler strips out of release
/// builds entirely -- this can't leak "free Premium" into a real build,
/// not even as dead code someone could re-enable by flipping a flag.
class DebugMockPremiumNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final debugMockPremiumProvider = NotifierProvider<DebugMockPremiumNotifier, bool>(DebugMockPremiumNotifier.new);

/// Live customer info, bridging RevenueCat's callback-style listener
/// into a stream Riverpod can watch. The listener fires immediately with
/// the last-known info as soon as it's added, and again on every
/// purchase/renewal/expiry -- including RevenueCat's own on-device cache,
/// so this still reports correctly offline.
///
/// Never emits when RevenueCat isn't configured -- isPremiumProvider's
/// own Env.hasRevenueCat check below is what actually matters; this just
/// avoids ever calling into an unconfigured SDK.
final customerInfoProvider = StreamProvider<CustomerInfo>((ref) {
  if (!Env.hasRevenueCat) return const Stream.empty();

  final controller = StreamController<CustomerInfo>();
  void listener(CustomerInfo info) => controller.add(info);
  Purchases.addCustomerInfoUpdateListener(listener);
  ref.onDispose(() {
    Purchases.removeCustomerInfoUpdateListener(listener);
    controller.close();
  });
  return controller.stream;
});

/// An admin-managed comp/allowlist, independent of RevenueCat -- checks
/// user_data.premium_overrides for the signed-in user's own row (RLS
/// only ever lets them see their own, never the full list -- see the
/// migration's doc comment). Null user or no Supabase configured both
/// resolve to false without a network call, same fail-closed shape as
/// customerInfoProvider below. Re-queries whenever currentUserProvider
/// changes (sign-in/out), since the override is keyed by user id.
final premiumOverrideProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  try {
    final row = await Supabase.instance.client
        .schema('user_data')
        .from('premium_overrides')
        .select('user_id')
        .eq('user_id', user.id)
        .maybeSingle();
    return row != null;
  } catch (_) {
    return false;
  }
});

/// Whether Premium is active right now. False whenever RevenueCat isn't
/// configured or customer info hasn't loaded yet -- Premium features
/// must fail closed (unavailable), never fail open (free access) while
/// status is unknown.
final isPremiumProvider = Provider<bool>((ref) {
  if (kDebugMode && ref.watch(debugMockPremiumProvider)) return true;
  if (ref.watch(premiumOverrideProvider).value ?? false) return true;
  if (!Env.hasRevenueCat) return false;
  final customerInfo = ref.watch(customerInfoProvider).value;
  return customerInfo?.entitlements.active.containsKey(premiumEntitlementId) ?? false;
});
