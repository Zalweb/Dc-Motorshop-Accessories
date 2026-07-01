from pydantic import BaseModel


class Page[ItemT](BaseModel):
    items: list[ItemT]
    page: int
    total: int
