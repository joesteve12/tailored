# Fabric inventory — Flutter feature (part 1 of 2)

This is the **read/browse** half: the inventory screen (list + search by serial /
fabric / customer), the per-serial detail screen with a jump to the order, and a
Home entry tile. It's self-contained — it has its own response models and does
**not** touch the order models — so it compiles and runs on its own, and it lights
up immediately against the fabric data your migration already populated.

## New files (drop in as-is)
- `lib/features/fabrics/models/fabric_inventory.dart` — `FabricInventoryItem`,
  `FabricInventoryDetail` (freezed; mirror the backend `/fabrics` responses).
- `lib/features/fabrics/data/fabric_repository.dart` — `GET /fabrics`,
  `GET /fabrics/{serial}`.
- `lib/features/fabrics/state/fabric_providers.dart` — search + list + detail providers.
- `lib/features/fabrics/screens/fabric_inventory_screen.dart` — list + debounced search.
- `lib/features/fabrics/screens/fabric_detail_screen.dart` — one fabric + order/customer.
- `lib/core/utils/fabric_labels.dart` — `formatFabricQuantity`.

## Changed files
- `lib/features/home/screens/home_tab_screen.dart` — adds a **Fabric inventory** tile.
- `lib/core/router/app_router.dart` — adds `/fabrics` and `/fabrics/:serial` routes.

## After copying in
Run codegen for the new freezed/json models:
```
dart run build_runner build --delete-conflicting-outputs
```
Then `dart analyze` and a hot restart. Entry point: **Home → Fabric inventory**.
The detail screen's "Open order" pushes `/orders/{id}`, which already exists.

(`dio_client` baseUrl already targets `/api/v1`, so the `/fabrics` calls resolve
with no change.)

## Heads-up: order-form fabric entry is the next pass
The backend change is breaking for the **order** screens, which still use the old
single-fabric shape. Until part 2 lands, with the new backend deployed:
- An order item won't show its fabric on the detail screen (the old flat
  `fabric_*` fields are gone; the item now carries a `fabrics` list).
- Creating/adding an item still sends the old flat fabric fields, which the new
  `OrderItemCreate` ignores — so items get **no** fabric rows.
- The edit sheet's fabric-image button calls the old
  `/uploads/order-items/{id}/fabric-image` path, which moved to
  `/uploads/fabrics/{fabricId}/image` — it will 404.

So either hold off pointing the app at the new backend for order *entry*, or
expect those rough edges until part 2. **Part 2** updates `OrderItem` /
`OrderItemInput` / `OrderRepository` and the two item sheets + the order detail
screen for true multi-fabric entry (add/remove fabrics, each showing its serial
to tag the cloth). That's the invasive, breaking pass — worth doing as its own
focused change.
