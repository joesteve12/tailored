# Patch: `lib/features/orders/screens/order_detail_screen.dart`

Two edits — one import, one widget insertion.

---

## 1. Add the import

Alongside the existing feature imports (near `import '../widgets/order_media_section.dart';`):

```diff
 import '../widgets/order_item_edit_sheet.dart';
 import '../widgets/order_item_form_sheet.dart';
 import '../widgets/order_media_section.dart';
+import '../widgets/order_activity_section.dart';
```

---

## 2. Insert the Activity section below `PaymentSection`

In the `data:` builder of the main `ListView`, find the block:

```dart
              const SizedBox(height: 20),
              PaymentSection(order: order),
              const SizedBox(height: 12),
              OrderDocumentActions(order: order),
```

Change it to:

```dart
              const SizedBox(height: 20),
              PaymentSection(order: order),
              const SizedBox(height: 20),
              OrderActivitySection(order: order),
              const SizedBox(height: 12),
              OrderDocumentActions(order: order),
```

That's the entire screen-level integration for Phase 1. `PaymentSection`
itself has been trimmed in this phase (see the new `payment_section.dart`)
so it now renders only the money summary + Record button — the payment
history and void action have moved into the Activity → Payments tab.

No changes needed anywhere else in this file. The rest of the screen
(header, status bar, items, media, edit dialogs) is untouched.
