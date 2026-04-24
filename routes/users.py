from fastapi import APIRouter, HTTPException, status
import hashlib
from database import users_collection
from models.user import User, UserLogin, UserPreferences
from bson import ObjectId

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

router = APIRouter(tags=["users"])

def fix_id(doc):
    doc["id"] = str(doc["_id"])
    del doc["_id"]
    return doc

@router.post("/users/register")
def register(user: User):
    existing = users_collection.find_one({"email": user.email})
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Email already registered"
        )
    new_user = user.dict()
    new_user["password"] = hash_password(user.password)
    users_collection.insert_one(new_user)
    return {"message": "Registered successfully"}

@router.post("/users/login")
def login(credentials: UserLogin):
    user = users_collection.find_one({
        "email": credentials.email,
        "password": hash_password(credentials.password)
    })
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Wrong email or password"
        )
    
    # ✅ الحل: حول لـ dict أول
    user = dict(user)
    user["_id"] = str(user["_id"])
    user.pop("password", None)
    
    return {"message": "Login successful", "user": user}

@router.put("/users/{user_id}/preferences")
def save_preferences(user_id: str, prefs: UserPreferences):
    result = users_collection.update_one(
        {"_id": ObjectId(user_id)},
        {"$set": {"preferences": prefs.dict()}}
    )
    if result.modified_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="User not found"
        )
    return {"message": "Preferences saved successfully"}

@router.get("/users/{user_id}")
def get_user(user_id: str):
    user = users_collection.find_one({"_id": ObjectId(user_id)})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="User not found"
        )
    user.pop("password", None) # Security: Never return password hash
    return fix_id(user)
