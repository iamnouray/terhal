from fastapi import APIRouter
from database import destinations_collection

router = APIRouter(prefix="/destinations", tags=["destinations"])

@router.get("/")
def get_all_destinations():
    places = list(destinations_collection.find({}, {"_id": 0}))
    return {"count": len(places), "data": places}

@router.get("/search")
def search_destinations(city: str = "", category: str = ""):
    query = {}
    if city: query["city"] = {"$regex": city, "$options": "i"}
    if category: query["category"] = {"$regex": category, "$options": "i"}
    results = list(destinations_collection.find(query, {"_id": 0}))
    return {"count": len(results), "data": results}

@router.get("/{name}")
def get_destination(name: str):
    place = destinations_collection.find_one({"name": name}, {"_id": 0})
    if not place:
        return {"error": "المكان غير موجود"}
    return place