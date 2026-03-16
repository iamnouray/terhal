from pydantic import BaseModel

class Like(BaseModel):
    user_id: str
    destination_id: str