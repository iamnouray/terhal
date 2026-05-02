from fastapi import APIRouter, HTTPException
from database import lists_collection
from models.list_item import ListItem

router = APIRouter(tags=["lists"])

@router.post("/lists")
def create_list(item: ListItem):
    existing = lists_collection.find_one({
        "user_id": item.user_id,
        "list_name": item.list_name
    })
    if existing:
        raise HTTPException(status_code=400, detail="List already exists")
    lists_collection.insert_one(item.dict())
    return {"message": "List created successfully"}

@router.get("/lists/{user_id}")
def get_user_lists(user_id: str):
    lists = list(lists_collection.find(
        {"user_id": user_id}, {"_id": 0}
    ))
    return {"count": len(lists), "data": lists}

@router.post("/lists/add-place")
def add_place_to_list(user_id: str, list_name: str, destination_id: str):
    result = lists_collection.update_one(
        {"user_id": user_id, "list_name": list_name},
        {"$addToSet": {"places": destination_id}}
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="List not found")
    return {"message": "Place added to list"}

@router.delete("/lists/remove-place")
def remove_place_from_list(user_id: str, list_name: str, destination_id: str):
    lists_collection.update_one(
        {"user_id": user_id, "list_name": list_name},
        {"$pull": {"places": destination_id}}
    )
    return {"message": "Place removed from list"}

@router.delete("/lists/{user_id}/{list_name}")
def delete_list(user_id: str, list_name: str):
    lists_collection.delete_one({
        "user_id": user_id,
        "list_name": list_name
    })
    return {"message": "List deleted"}