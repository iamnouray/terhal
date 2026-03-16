from pydantic import BaseModel
from typing import Optional

class ListItem(BaseModel):
    user_id: str
    destination_id: str
    list_name: Optional[str] = "My List"