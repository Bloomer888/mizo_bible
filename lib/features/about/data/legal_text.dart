/// Privacy policy and terms of service body text, as plain constants
/// rather than routed through the ARB/l10n system -- this is long-form
/// prose, English-only like the rest of the app's UI strings, and ARB's
/// single-line-friendly JSON format is awkward for paragraph text.
/// Grounded in what the app actually does as of Phase 9 (email auth)
/// and Phase 8 (Supabase sync), not generic boilerplate -- update this
/// alongside any future change to what data the app collects or how.
library;

const String privacyPolicyText = '''
Last updated: October 2026

Mizo Bible is built to work fully offline, with no account required to
read, search, bookmark, highlight, or take notes. Everything below
only applies if you choose to create an account.

WHAT WE COLLECT

If you create an account: the email address and password you provide.
Your password is handled entirely by our authentication provider,
Supabase -- the app itself never stores or sees it after sign-in.

If you create an account and stay signed in: your bookmarks,
highlights, notes, reading history, reading progress, and app
preferences are synced to Supabase's servers so they're available on
your other devices. This same data is always stored on your own
device regardless of whether you're signed in.

We do not collect analytics, advertising identifiers, device
identifiers, location data, or any data beyond what's listed above.
The app contains no ads and no third-party trackers.

HOW IT'S USED

Solely to provide the app's own features: signing you in, and syncing
your bookmarks/highlights/notes/history/progress across your devices.
We don't sell, rent, or share this data with anyone else.

WHERE IT'S STORED

Your account and synced data are stored by Supabase, our backend
provider, protected so that only your own signed-in account can read
or write it. Unsynced, locally-only data never leaves your device.

DELETING YOUR DATA

You can permanently erase your bookmarks, highlights, notes, history,
and progress -- both on your device and from our servers -- from the
Account screen at any time, without needing to contact anyone. Signing
out on its own does not delete anything; it only ends your session.

CHILDREN

This app is not directed at children under 13 and we do not knowingly
collect data from them.

CONTACT

Questions about this policy: larc1406@gmail.com
''';

const String termsOfServiceText = '''
Last updated: October 2026

By using Mizo Bible, you agree to these terms.

THE APP

Mizo Bible is free to use. The Bible text itself, its licensing, and
its source are described separately on the Bible Text screen -- these
terms don't change or expand what you're allowed to do with that text
beyond what's stated there.

ACCOUNTS

Creating an account is optional and only needed for syncing your
bookmarks, highlights, notes, and reading history/progress across
devices. You're responsible for keeping your password safe. You can
delete your account's synced data at any time from the Account screen.

ACCEPTABLE USE

Use the app for its intended purpose -- reading, studying, and
personally annotating the Bible text. Don't attempt to disrupt the
service, access another user's account or data, or use the app for
anything unlawful.

NO WARRANTY

The app is provided as-is. We work to keep the Bible text accurate to
its source, but we don't guarantee the app will be error-free or
available without interruption.

CHANGES

These terms may be updated as the app changes; continued use after an
update means you accept the revised terms.

GOVERNING LAW

These terms are governed by the laws of India.

CONTACT

Questions about these terms: larc1406@gmail.com
''';
