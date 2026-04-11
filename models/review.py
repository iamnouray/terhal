from pydantic import BaseModel, Field

class Review(BaseModel):
    user_id: str
    destination_id: str
    rating: float = Field(..., ge=1.0, le=5.0)
    comment: str