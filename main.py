from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import destinations, users, recommendations, likes, reviews
from database import check_db_connection

app = FastAPI(title="Terhal API")

# Setup CORS to allow Flutter Web to communicate with the Backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Startup event to check DB connection
@app.on_event("startup")
async def startup_db_client():
    await check_db_connection()

# Include Routers
# Note: Ensure that your login logic is inside the 'users' router
app.include_router(destinations.router)
app.include_router(users.router)
app.include_router(recommendations.router)
app.include_router(likes.router)
app.include_router(reviews.router)

@app.get("/")
async def root():
    return {"message": "Welcome to Terhal API"}