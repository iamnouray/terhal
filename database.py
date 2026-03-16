import os
import certifi
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

client = MongoClient(os.getenv("MONGODB_URL"), tls=True, tlsAllowInvalidCertificates=True)
db = client[os.getenv("DATABASE_NAME", "terhal_db")]

destinations_collection = db["destinations"]
users_collection = db["users"]
reviews_collection = db["reviews"]

print("✅ Connected to MongoDB:", db.name)
likes_collection = db["likes"]
lists_collection = db["lists"]