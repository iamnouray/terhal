from pydantic import BaseModel
from typing import Optional, List

class UserPreferences(BaseModel):
    city: Optional[str] = None
    visitor_type: Optional[str] = None        # solo, friends, couple, family
    preferred_time: Optional[str] = None      # Morning, Afternoon, Evening, Night
    environment: Optional[str] = None         # Indoor, Outdoor
    budget: Optional[str] = None              # $, $$, $$$
    mood: Optional[str] = None                # calm, energetic, adventurous, relaxed
    activity_type: Optional[str] = None       # breakfast, lunch, dinner, shopping, views

class User(BaseModel):
    username: str
    email: str
    password: str
    preferences: Optional[UserPreferences] = None

class UserLogin(BaseModel):
    email: str
    password: str