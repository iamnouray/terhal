from pydantic import BaseModel

class Review(BaseModel):
    user_id: str
    destination_id: str
    rating: float
    comment: str