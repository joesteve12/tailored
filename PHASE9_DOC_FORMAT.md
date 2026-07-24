# Document format choice (PDF or image)

Follow-up to Phase 9. Drop in over your project — no new packages, no codegen.

## What changed
Sharing any document — invoice, receipt, or per-item work order — now asks
"Share as PDF" or "Share as image" first, fetches that `format` from the
endpoint, and shares it with the right extension/mime (.pdf/application/pdf or
.png/image/png). A short caption is attached too (e.g. "Invoice · order 1042").

- lib/core/utils/share_document.dart
    + DocFormat enum, DocFormatX (apiValue / extension / mimeType / label),
      and pickDocumentFormat() — a small PDF/image bottom-sheet chooser.
- lib/features/documents/widgets/order_document_actions.dart
    invoice + receipt now go through the chooser.
- lib/features/orders/widgets/order_item_assignments_section.dart
    "Send work order" now goes through the chooser.

## On pre-selecting the WhatsApp recipient
Not possible for a file attachment. The OS share sheet doesn't accept a target
contact, and WhatsApp's wa.me / "click to chat" deep links only prefill a text
message — they can't carry a file. Pre-addressing a specific number with an
attachment requires the paid WhatsApp Business Cloud API (with an approved
template). So the owner still picks the chat in the share sheet.

If a text-only "your order is ready" nudge to a specific number is useful, that
*is* doable via a wa.me deep link (needs url_launcher + the client/employee
phone) — but it would be a separate action from the file share, not a way to
attach the document to that chat. Happy to add it if you want it.
