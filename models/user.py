from pydantic import BaseModel
from typing import Optional

class UserPreferences(BaseModel):
    city: Optional[str] = None            # riyadh, jeddah, abha, alula, madinah
    visitor_type: Optional[str] = None    # solo, friends, family, couple
    preferred_time: Optional[str] = None  # morning, afternoon, evening, late night
    mood: Optional[str] = None            # adventurous, relaxed, energetic, calm & quiet
    activity: Optional[str] = None        # breakfast, lunch/dinner, coffee, shopping, scenic drive & views
    budget: Optional[str] = None          # $, $$, $$$
    environment: Optional[str] = None     # Indoor, Outdoor

class User(BaseModel):
    username: str
    email: str
    password: str
    preferences: Optional[UserPreferences] = None

class UserLogin(BaseModel):
    email: str
    password: str