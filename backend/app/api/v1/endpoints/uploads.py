from fastapi import APIRouter, Depends, File, UploadFile
from fastapi.responses import FileResponse
from pydantic import BaseModel

from app.api import deps
from app.services.storage_service import resolve_local_upload_path, upload_image
from app.services.tenant_context_service import TenantContext

router = APIRouter()


class UploadImageOut(BaseModel):
    url: str
    key: str
    content_type: str
    size_bytes: int
    storage: str


@router.post("/images", response_model=UploadImageOut)
async def upload_product_image(
    file: UploadFile = File(...),
    ctx: TenantContext = Depends(deps.get_tenant_context),
):
    """Upload and optimize a product image to Cloudflare R2 (or local storage in dev)."""
    raw_bytes = await file.read()
    res = upload_image(raw_bytes, file.content_type, ctx.boutique.id)
    return UploadImageOut(
        url=res.url,
        key=res.key,
        content_type=res.content_type,
        size_bytes=res.size_bytes,
        storage=res.storage,
    )


@router.get("/files/{boutique_id}/{filename}")
def get_local_uploaded_image(boutique_id: str, filename: str):
    """Serve locally persisted product images when running without Cloudflare R2."""
    file_path = resolve_local_upload_path(boutique_id, filename)
    return FileResponse(path=str(file_path))
