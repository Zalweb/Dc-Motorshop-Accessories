"""S3-compatible image storage with upload validation.

Security (BACKEND_PLAN §2 file upload): allow only image MIME types, verify magic bytes
(not just the declared type), cap size, store under a random key (never the client
filename), in a private bucket, and serve via a time-limited signed URL.

NOTE(zalweb): EXIF stripping is deferred — it needs Pillow; tracked for a hardening pass.
"""

import boto3
from botocore.config import Config

from app.core.config import get_settings
from app.core.errors import AppError
from app.core.ids import uuid7

MAX_IMAGE_BYTES = 5 * 1024 * 1024  # 5 MB
SIGNED_URL_TTL_SECONDS = 3600

_EXTENSION_BY_TYPE = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/gif": "gif",
    "image/webp": "webp",
}

# (content_type, magic-byte prefix predicate)
_MAGIC = {
    "image/jpeg": lambda b: b[:3] == b"\xff\xd8\xff",
    "image/png": lambda b: b[:8] == b"\x89PNG\r\n\x1a\n",
    "image/gif": lambda b: b[:6] in (b"GIF87a", b"GIF89a"),
    "image/webp": lambda b: b[:4] == b"RIFF" and b[8:12] == b"WEBP",
}


def validate_image(data: bytes, content_type: str) -> None:
    if len(data) > MAX_IMAGE_BYTES:
        raise AppError(code="file_too_large", message="Image exceeds 5 MB", status_code=413)
    if content_type not in _MAGIC:
        raise AppError(
            code="unsupported_media_type",
            message="Only JPEG, PNG, GIF, or WEBP images are allowed",
            status_code=415,
        )
    if not _MAGIC[content_type](data):
        # Declared type and actual bytes disagree → reject (spoofed extension/MIME).
        raise AppError(
            code="invalid_image",
            message="File content does not match its declared image type",
            status_code=415,
        )


def build_s3_client():
    settings = get_settings()
    return boto3.client(
        "s3",
        endpoint_url=settings.s3_endpoint_url,
        region_name=settings.s3_region,
        aws_access_key_id=settings.s3_access_key,
        aws_secret_access_key=settings.s3_secret_key,
        config=Config(signature_version="s3v4"),
    )


class StorageService:
    def __init__(self, client, bucket: str) -> None:
        self.client = client
        self.bucket = bucket

    def upload_image(self, data: bytes, content_type: str) -> tuple[str, str]:
        validate_image(data, content_type)
        key = f"products/{uuid7().hex}.{_EXTENSION_BY_TYPE[content_type]}"
        self.client.put_object(
            Bucket=self.bucket, Key=key, Body=data, ContentType=content_type
        )
        url = self.client.generate_presigned_url(
            "get_object",
            Params={"Bucket": self.bucket, "Key": key},
            ExpiresIn=SIGNED_URL_TTL_SECONDS,
        )
        return key, url
