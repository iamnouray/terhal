from pydantic import BaseModel
from typing import Optional

class Destination(BaseModel):
    name: str
    city: Optional[str] = None
    category: Optional[str] = None
    rating: Optional[float] = None
    description: Optional[str] = None
    region: Optional[str] = None
    