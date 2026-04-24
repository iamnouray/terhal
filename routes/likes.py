from fastapi import APIRouter
from database import likes_collection
from models.like import Like

router = APIRouter(tags=["likes"])

@router.post("/likes")
def toggle_like(like: Like):
    existing = likes_collection.find_one({
        "user_id": like.user_id,
        "destination_id": like.destination_id
    })
    if existing:
        likes_collection.delete_one({
            "user_id": like.user_id,
            "destination_id": like.destination_id
        })
        return {"message": "Like removed"}
    else:
        likes_collection.insert_one(like.dict())
        return {"message": "Like added"}

@router.get("/likes/{user_id}")
def get_user_likes(user_id: str):
    likes = list(likes_collection.find(
        {"user_id": user_id}, {"_id": 0}
    ))
    return {"count": len(likes), "data": likes}
