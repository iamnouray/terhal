from fastapi import APIRouter, Query
from typing import Optional
from ai.recommender import get_recommendations
from database import users_collection
from bson import ObjectId

router = APIRouter(prefix="/recommend", tags=["recommendations"])

@router.get("/{user_id}")
def recommend(
    user_id: str,
    top_n: int = 5,
    city: Optional[str] = Query(None),
    visitor_type: Optional[str] = Query(None),
    preferred_time: Optional[str] = Query(None),
    environment: Optional[str] = Query(None),
    budget: Optional[str] = Query(None),
    mood: Optional[str] = Query(None),
    activity_type: Optional[str] = Query(None)
):
    # If no context passed → load from user's saved preferences
    if not any([city, visitor_type, preferred_time, environment, budget]):
        try:
            user = users_collection.find_one({"_id": ObjectId(user_id)})
            if user and "preferences" in user:
                prefs = user["preferences"]
                city = city or prefs.get("city")
                visitor_type = visitor_type or prefs.get("visitor_type")
                preferred_time = preferred_time or prefs.get("preferred_time")
                environment = environment or prefs.get("environment")
                budget = budget or prefs.get("budget")
                mood = mood or prefs.get("mood")
                activity_type = activity_type or prefs.get("activity_type")
        except:
            pass

    results = get_recommendations(
        user_id=user_id,
        top_n=top_n,
        city=city,
        visitor_type=visitor_type,
        preferred_time=preferred_time,
        environment=environment,
        budget=budget
    )
    return {"user_id": user_id, "recommendations": results}