from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware # أضيفي هذا السطر
from routes import destinations, users, recommendations, likes, reviews
from database import check_db_connection

app = FastAPI(title="Terhal API")

# --- أضيفي هذا الجزء للسماح لـ Flutter بالوصول للبيانات ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # يسمح لكل المواقع (مناسب للتطوير)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# --------------------------------------------------

@app.on_event("startup")
async def startup_db_client():
    await check_db_connection()

app.include_router(destinations.router)
app.include_router(users.router)
app.include_router(recommendations.router)
app.include_router(likes.router)
app.include_router(reviews.router)

@app.get("/")
async def root():
    return {"message": "Welcome to Terhal API"}