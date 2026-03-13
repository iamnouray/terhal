from fastapi import APIRouter
from database import users_collection
from models.user import User

router = APIRouter(tags=["users"])

@router.post("/users/register")
def register(user: User):
    existing = users_collection.find_one({"email": user.email})
    if existing:
        return {"error": "Email already registered"}
    users_collection.insert_one(user.dict())
    return {"message": "Registered successfully"}

@router.post("/users/login")
def login(email: str, password: str):
    user = users_collection.find_one({"email": email, "password": password}, {"_id": 0})
    if not user:
        return {"error": "Wrong email or password"}
    return {"message": "Login successful", "user": user}