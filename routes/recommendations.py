from fastapi import APIRouter, Query
from typing import Optional
from ai.recommender import get_recommendations
from database import users_collection
from bson import ObjectId

router = APIRouter(prefix="/recommend", tags=["recommendations"])

@router.get("/{user_id}")
def recommend(
    user_id: str,
    top_n: int = 10,
    city: Optional[str] = Query(None),
    visitor_type: Optional[str] = Query(None),
    preferred_time: Optional[str] = Query(None),
    environment: Optional[str] = Query(None),
    budget: Optional[str] = Query(None),
):
    survey = {}
    try:
        user = users_collection.find_one({"_id": ObjectId(user_id)})
        if user and "preferences" in user:
            survey = user["preferences"]
    except:
        pass

    results = get_recommendations(
        user_id=user_id,
        survey=survey,
        top_n=top_n,
        city=city,
        visitor_type=visitor_type,
        preferred_time=preferred_time,
        environment=environment,
        budget=budget,
    )
    return {"user_id": user_id, "recommendations": results}