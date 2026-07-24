/// Hero tags, in one place.
///
/// ⚠️ THE RULE: a Hero tag must be **unique within a single route**. Two Heroes
/// sharing a tag on the same screen is not a warning — Flutter throws
/// ("There are multiple heroes that share the same tag within a subtree") and
/// the screen dies. The failure surfaces wherever the duplicate is, which is
/// usually nowhere near the code that caused it.
///
/// The same tag on *different* routes is not just fine, it's the point — that's
/// how the flight is matched between the screen you left and the screen you
/// landed on.
library;

/// Tag for a client's avatar, so it flies between wherever it's listed and the
/// client detail screen.
///
/// Currently used on exactly three screens, each of which shows a given client
/// **at most once**:
///   • the client list (one row per client)
///   • the order detail screen's "Belongs to" tile (an order has one client)
///   • the client detail screen (the destination)
///
/// ⚠️ Before adding a client avatar anywhere else, check the screen can't show
/// the same client twice. The obvious trap is an order list with client
/// avatars: two orders from the same client on screen = the same tag twice =
/// crash. If you need that, don't reuse this tag — give those avatars no Hero
/// at all, or a tag scoped to the *order* id.
String clientPhotoHeroTag(String clientId) => 'client-photo-$clientId';
