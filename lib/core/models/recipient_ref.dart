/// Discriminates which kind of person a measurement or an order item
/// belongs to. Mirrors the backend's client_id / guest_recipient_id
/// pattern — exactly one of the two is ever set (a DB check constraint
/// on the measurements table; OrderItemCreate/Response use the identical
/// recipient_type / recipient_client_id / guest_recipient_id shape).
enum RecipientType { client, guest }

/// A lightweight, value-equatable reference to "this client" or "this
/// guest" — a Dart 3 record, not a hand-rolled class, specifically so it
/// works as a Riverpod `.family` argument for free: records get
/// structural `==`/`hashCode` automatically, which is exactly what the
/// family cache needs to key on. No equatable package, no manual
/// override, nothing to get wrong.
///
/// Lives in core/ (moved here from the measurements feature, which is
/// where it was originally introduced) because both Measurements and
/// Orders need the identical client-or-guest distinction.
typedef RecipientRef = ({RecipientType type, String id});

extension RecipientRefX on RecipientRef {
  bool get isClient => type == RecipientType.client;
  bool get isGuest => type == RecipientType.guest;
}

RecipientRef clientRecipient(String clientId) =>
    (type: RecipientType.client, id: clientId);

RecipientRef guestRecipient(String guestId) =>
    (type: RecipientType.guest, id: guestId);
