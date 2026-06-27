# events_schema.py -- authoritative schema for the events table.
from enum import Enum
from uuid import UUID
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

class EventType(str, Enum):
    click = "click"
    view = "view"
    purchase = "purchase"

class Event(BaseModel):
    event_id: UUID = Field(description="Globally unique, immutable identifier")
    user_id: UUID = Field(description="Foreign key to user_profiles table")
    event_type: EventType
    timestamp: datetime = Field(description="UTC timestamp, monotonically increasing per user")
    payload: Optional[dict] = Field(default=None, max_length=4096)
