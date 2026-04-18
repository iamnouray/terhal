import os
import certifi
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv

load_dotenv()


MONGODB_URL = os.getenv("MONGODB_URL")
DATABASE_NAME = os.getenv("DATABASE_NAME", "terhal_db")


client = AsyncIOMotorClient(MONGODB_URL, tlsCAFile=certifi.where())
db = client[DATABASE_NAME]

destinations_collection = db["destinations"]
users_collection = db["users"]
reviews_collection = db["reviews"]
likes_collection = db["likes"]
lists_collection = db["lists"]


async def check_db_connection():
    try:
        await client.admin.command('ping')
        print(f"✅ Connected to MongoDB: {DATABASE_NAME}")
    except Exception as e:
        print(f"❌ Connection failed: {e}")