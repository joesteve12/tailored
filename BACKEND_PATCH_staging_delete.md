# Backend addition required for staged-media cleanup (Issue 2)

The frontend now deletes staged-but-never-attached uploads when a create flow
is abandoned or a staged file is removed before saving. That needs one new
endpoint, which doesn't exist yet. It's small and reuses the existing
`safe_delete_file` helper that the other delete routes already use.

## Add to `app/routers/uploads.py`

Paste this right **after** the `upload_staging_media` handler (before the
`# ── Logo ──` section). No new imports are needed — `safe_delete_file`,
`User`, and `get_current_user` are already imported in this file.

```python
@router.delete(
    "/staging/{file_id}",
    status_code=204,
    summary="Delete a staged file that was never attached (orphan cleanup)",
)
async def delete_staging_file(
    file_id: str,
    current_user: User = Depends(get_current_user),
):
    # Staged files aren't linked to any DB record yet, so there's no ownership
    # row to check; the file_id is an opaque ImageKit handle returned only to
    # the uploader. Best-effort delete so an abandoned create flow (or a
    # staged item removed before save) doesn't orphan media on ImageKit.
    await safe_delete_file(file_id)
```

## Behaviour without this endpoint

The frontend calls `DELETE /uploads/staging/{file_id}` as fire-and-forget and
swallows any error (see `OrderRepository.deleteStagedFile`). Until the route
is deployed those calls just 404 silently — nothing breaks, but the orphans
aren't cleaned up. Once deployed, cleanup starts working with no further
frontend change.
