from fastapi import APIRouter

router = APIRouter(prefix="/recommend", tags=["recommendations"])

@router.get("/{user_id}")
def recommend(user_id: str):
    return {"message": "Recommendations coming in Phase 3", "user_id": user_id}