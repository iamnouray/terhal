from pydantic import BaseModel
from typing import Optional, List

class ListItem(BaseModel):
    user_id: str
    list_name: str = "My List"
    destination_id: Optional[str] = None
    places: Optional[List[str]] = []