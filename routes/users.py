from fastapi import APIRouter, HTTPException
from database import users_collection
from models.user import User, UserLogin, UserPreferences
from bson import ObjectId

router = APIRouter(tags=["users"])

def fix_id(doc):
    doc["id"] = str(doc["_id"])
    del doc["_id"]
    return doc

# ── Register ──────────────────────────────────────────────────────
@router.post("/users/register")
def register(user: User):
    existing = users_collection.find_one({"email": user.email})
    if existing:
        return {"error": "Email already registered"}
    users_collection.insert_one(user.dict())
    return {"message": "Registered successfully"}

# ── Login ─────────────────────────────────────────────────────────
@router.post("/users/login")
def login(credentials: UserLogin):
    user = users_collection.find_one({
        "email": credentials.email,
        "password": credentials.password
    }, {"_id": 0})
    if not user:
        return {"error": "Wrong email or password"}
    return {"message": "Login successful", "user": user}

# ── Save survey preferences ───────────────────────────────────────
@router.put("/users/{user_id}/preferences")
def save_preferences(user_id: str, prefs: UserPreferences):
    result = users_collection.update_one(
        {"_id": ObjectId(user_id)},
        {"$set": {"preferences": prefs.dict()}}
    )
    if result.modified_count == 0:
        return {"error": "User not found"}
    return {"message": "Preferences saved successfully"}

# ── Get user profile ──────────────────────────────────────────────
@router.get("/users/{user_id}")
def get_user(user_id: str):
    user = users_collection.find_one({"_id": ObjectId(user_id)})
    if not user:
        return {"error": "User not found"}
    return fix_id(user)