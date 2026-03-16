from fastapi import APIRouter
from database import reviews_collection
from models.review import Review

router = APIRouter(tags=["reviews"])

# Add a review
@router.post("/reviews")
def add_review(review: Review):
    reviews_collection.insert_one(review.dict())
    return {"message": "Review added successfully"}

# Get reviews for a place
@router.get("/reviews/{destination_id}")
def get_reviews(destination_id: str):
    reviews = list(reviews_collection.find(
        {"destination_id": destination_id}, {"_id": 0}
    ))
    return {"count": len(reviews), "data": reviews}

# Get all reviews by a user
@router.get("/reviews/user/{user_id}")
def get_user_reviews(user_id: str):
    reviews = list(reviews_collection.find(
        {"user_id": user_id}, {"_id": 0}
    ))
    return {"count": len(reviews), "data": reviews}