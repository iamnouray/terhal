from fastapi import APIRouter
from database import likes_collection, lists_collection
from models.like import Like
from models.list_item import ListItem

router = APIRouter(tags=["likes & lists"])

# ── Add like ──────────────────────────────
@router.post("/likes")
def add_like(like: Like):
    existing = likes_collection.find_one({
        "user_id": like.user_id,
        "destination_id": like.destination_id
    })
    if existing:
        return {"message": "Already liked"}
    likes_collection.insert_one(like.dict())
    return {"message": "Liked successfully"}

# ── Remove like ───────────────────────────
@router.delete("/likes")
def remove_like(user_id: str, destination_id: str):
    likes_collection.delete_one({
        "user_id": user_id,
        "destination_id": destination_id
    })
    return {"message": "Like removed"}

# ── Get all likes for a user ──────────────
@router.get("/likes/{user_id}")
def get_likes(user_id: str):
    likes = list(likes_collection.find(
        {"user_id": user_id}, {"_id": 0}
    ))
    return {"count": len(likes), "data": likes}

# ── Add to list ───────────────────────────
@router.post("/lists")
def add_to_list(item: ListItem):
    existing = lists_collection.find_one({
        "user_id": item.user_id,
        "destination_id": item.destination_id
    })
    if existing:
        return {"message": "Already in list"}
    lists_collection.insert_one(item.dict())
    return {"message": "Added to list"}

# ── Remove from list ──────────────────────
@router.delete("/lists")
def remove_from_list(user_id: str, destination_id: str):
    lists_collection.delete_one({
        "user_id": user_id,
        "destination_id": destination_id
    })
    return {"message": "Removed from list"}

# ── Get all list items for a user ─────────
@router.get("/lists/{user_id}")
def get_list(user_id: str):
    items = list(lists_collection.find(
        {"user_id": user_id}, {"_id": 0}
    ))
    return {"count": len(items), "data": items}