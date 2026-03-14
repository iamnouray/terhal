from fastapi import APIRouter
from database import users_collection, reviews_collection
from models.user import User
from models.review import Review

router = APIRouter(tags=["users"])

# Register new user
@router.post("/users/register")
def register(user: User):
    existing = users_collection.find_one({"email": user.email})
    if existing:
        return {"error": "Email already registered"}
    users_collection.insert_one(user.dict())
    return {"message": "Registered successfully"}

# Login
@router.post("/users/login")
def login(email: str, password: str):
    user = users_collection.find_one(
        {"email": email, "password": password}, {"_id": 0}
    )
    if not user:
        return {"error": "Wrong email or password"}
    return {"message": "Login successful", "user": user}

# Add review
@router.post("/reviews")
def add_review(review: Review):
    reviews_collection.insert_one(review.dict())
    return {"message": "Review added successfully"}

# Get reviews for a destination
@router.get("/reviews/{destination_id}")
def get_reviews(destination_id: str):
    reviews = list(reviews_collection.find(
        {"destination_id": destination_id}, {"_id": 0}
    ))
    return {"count": len(reviews), "data": reviews}