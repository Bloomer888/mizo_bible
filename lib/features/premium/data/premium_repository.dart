import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/env.dart';

/// Must match the entitlement identifier configured in the RevenueCat
/// dashboard -- RevenueCat's own concept, not a Play Console product id.
const premiumEntitlementId = 'premium';

/// Associates RevenueCat's purchase history with the signed-in Supabase
/// user, so Premium bought on one device is recognised the moment they
/// sign in on another. Call right at sign-in, not deferred until someone
/// opens the paywall -- otherwise a returning Premium user would briefly
/// (and wrongly) look unentitled.
///
/// Best-effort and silent, same reasoning as sync's own
/// `_syncIfSignedIn`: a failure here must never block sign-in itself.
/// RevenueCat retries identity resolution on its own on next launch.
Future<void> linkPremiumIdentity(String userId) async {
  if (!Env.hasRevenueCat) return;
  try {
    await Purchases.logIn(userId);
  } catch (_) {
    // Swallowed deliberately -- see doc comment above.
  }
}

Future<void> unlinkPremiumIdentity() async {
  if (!Env.hasRevenueCat) return;
  try {
    await Purchases.logOut();
  } catch (_) {
    // Swallowed deliberately -- see doc comment above.
  }
}
