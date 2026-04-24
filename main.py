from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import destinations, users, recommendations, likes, reviews

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(destinations.router)
app.include_router(users.router)
app.include_router(recommendations.router)
app.include_router(likes.router)
app.include_router(reviews.router)

