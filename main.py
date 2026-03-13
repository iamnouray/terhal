from fastapi import FastAPI
from routes import destinations, users, recommendations

app = FastAPI()

app.include_router(destinations.router)
app.include_router(users.router)
app.include_router(recommendations.router)