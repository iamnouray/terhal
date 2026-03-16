from fastapi import APIRouter
from database import reviews_collection
from models.review import Review

router = APIRouter(prefix="/reviews", tags=["reviews"])


# ── Add review ────────────────────────────────────────────────────
@router.post("/")
def add_review(review: Review):
    reviews_collection.insert_one(review.dict())
    return {"message": "Review added successfully"}


# ── Get reviews for a destination ─────────────────────────────────
@router.get("/{destination_id}")
def get_reviews(destination_id: str):
    reviews = list(reviews_collection.find(
        {"destination_id": destination_id}, {"_id": 0}
    ))
    return {"count": len(reviews), "data": reviews}


# ── Get reviews by user ───────────────────────────────────────────
@router.get("/user/{user_id}")
def get_user_reviews(user_id: str):
    reviews = list(reviews_collection.find(
        {"user_id": user_id}, {"_id": 0}
    ))
    return {"count": len(reviews), "data": reviews}


# ── Delete review ─────────────────────────────────────────────────
@router.delete("/")
def delete_review(user_id: str, destination_id: str):
    result = reviews_collection.delete_one({
        "user_id": user_id,
        "destination_id": destination_id
    })
    if result.deleted_count == 0:
        return {"error": "Review not found"}
    return {"message": "Review deleted successfully"}