"""Shared Pydantic base: reject unknown fields everywhere (defense against mass-assignment)."""

from pydantic import BaseModel, ConfigDict


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class ORMModel(BaseModel):
    """Response models read from ORM objects."""

    model_config = ConfigDict(from_attributes=True)
