# Fabric — Flutter feature (part 2 of 2): multi-fabric order entry + Settings entry

This is the breaking half. It rewrites the order item's fabric shape from the old
single-fabric fields to a **list of fabrics**, wires the create/edit flows to add
/ edit / remove fabrics (each showing its server-generated serial so you can tag
the cloth), shows fabrics on the order detail, and moves the inventory entry
point from Home to **Settings**.

Drop these over your project (paths map 1:1). Run codegen + analyze after.

## New file
- `lib/features/orders/models/fabric.dart` — `Fabric` (response, freezed) +
  `FabricInput` (request helper).

## Changed files
- `lib/features/orders/models/order_item.dart` — `fabrics: List<Fabric>` replaces
  `fabricSerial`/`fabricDetails`/`fabricImageUrl`; `OrderItemInput.fabrics` +
  `primaryFabricImageUrl` helper.
- `lib/features/orders/data/order_repository.dart` — fabric CRUD
  (`addFabric` / `updateFabric` / `deleteFabric`), per-fabric image
  (`uploadFabricImage(fabricId,…)` / `deleteFabricImage(fabricId)`),
  `updateItem` drops `fabricDetails`.
- `lib/features/orders/state/order_detail_notifier.dart` — matching fabric
  methods (`addFabric` returns the new `Fabric` so the UI can show its serial).
- `lib/features/orders/widgets/order_item_form_sheet.dart` — create flow: a
  repeatable fabric editor (details / quantity / unit / staged image per fabric).
- `lib/features/orders/widgets/order_item_edit_sheet.dart` — existing item: a
  fabric manager (add → toast with the new serial, edit, delete, per-fabric image).
- `lib/features/orders/screens/order_detail_screen.dart` — item card lists every
  fabric (serial · details · qty) and thumbnails the first one.
- `lib/core/utils/fabric_labels.dart` — adds `kFabricUnits` (overwrites the part‑1
  copy; `formatFabricQuantity` is unchanged).
- `lib/features/settings/screens/settings_screen.dart` — **Fabric inventory** tile
  under a new "Inventory" section.
- `lib/features/home/screens/home_tab_screen.dart` — **reverts** the part‑1 Home
  tile (inventory now lives in Settings). Make sure this overwrites the part‑1
  version.

## Keep from part 1
The `/fabrics` and `/fabrics/:serial` routes you added to `app_router.dart` in
part 1 stay as-is — they're now reached from Settings. No router change here.

## After copying in
```
dart run build_runner build --delete-conflicting-outputs
dart analyze
```
`build_runner` regenerates `fabric.freezed.dart` / `fabric.g.dart` and the
updated `order_item.*`. There's no Dart SDK in my sandbox, so I couldn't run
codegen or the analyzer — please run both and skim for nits. Delimiter balance
and the cross-file reference sweep are clean (no leftover `fabricSerial` /
`fabricDetails` / old endpoint anywhere).

## Flow notes
- **Create order / add item:** the item sheet now has an "Add fabric" button;
  each fabric takes optional details, quantity + unit (defaults to yards), and an
  optional image (staged, cleaned up if you abandon the sheet). Serials are
  assigned server-side on save and show up afterward on the order/inventory.
- **Edit an existing item:** the Fabrics section adds/edits/removes fabrics live
  against the new endpoints. Adding one pops a toast with its serial to tag.
  Per-fabric image is in each fabric's "⋮" menu.
- **Inventory (part 1):** Settings → Fabric inventory, search by serial, tap a
  fabric → Open order.
