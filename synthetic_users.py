import os
import random
import hashlib
from datetime import datetime, timedelta

import certifi
from dotenv import load_dotenv
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError
from bson import ObjectId

load_dotenv()

# =========================================================
# CONFIG
# =========================================================
MONGODB_URL = os.getenv("MONGODB_URL")
DATABASE_NAME = os.getenv("DATABASE_NAME", "terhal_db")

if not MONGODB_URL:
    raise ValueError("MONGODB_URL is missing from .env")

CITIES = ["Riyadh", "Jeddah", "AlUla", "Abha", "Madinah"]
VISITOR_TYPES = ["family", "solo", "friends", "couple"]
TIMES = ["Morning", "Afternoon", "Evening", "Late Night"]
MOODS = ["adventurous", "relaxed", "energetic", "calm & quiet"]
ACTIVITIES = [
    "breakfast",
    "lunch / dinner",
    "coffee",
    "shopping",
    "scenic drive & views",
]
BUDGETS = ["$", "$$", "$$$"]
ENVIRONMENTS = ["Indoor", "Outdoor"]

SAMPLE_COMMENTS = [
    "Absolutely loved this place, will definitely come back!",
    "Great atmosphere and very clean. Highly recommended.",
    "Nice spot but a bit crowded on weekends.",
    "Good experience overall, staff were friendly.",
    "Wonderful views and peaceful environment.",
    "Food was amazing, prices are reasonable.",
    "Perfect for a family outing. Kids loved it.",
    "A hidden gem in the city. Very authentic.",
    "Decent place but parking was difficult.",
    "One of the best spots I've visited in Saudi Arabia.",
    "Loved the traditional architecture and history.",
    "Great for a morning walk with coffee.",
    "The sunset view here is breathtaking.",
    "Very well maintained. Clean and organized.",
    "A bit overrated but still enjoyable.",
    "Perfect date spot. Romantic ambiance.",
    "Excellent service and beautiful surroundings.",
    "Worth every riyal. Will bring friends next time.",
]

TEST_PASSWORD = "Test12345"


# =========================================================
# HELPERS
# =========================================================
def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()


def random_date_within_days(days: int = 180) -> datetime:
    delta = timedelta(
        days=random.randint(0, days),
        hours=random.randint(0, 23),
        minutes=random.randint(0, 59),
    )
    return datetime.utcnow() - delta


def connect_to_db():
    try:
        client = MongoClient(
            MONGODB_URL,
            tlsCAFile=certifi.where(),
            serverSelectionTimeoutMS=8000,
        )
        client.admin.command("ping")
        print("✅ Connected to MongoDB Atlas successfully.")
        return client[DATABASE_NAME]
    except (ConnectionFailure, ServerSelectionTimeoutError) as e:
        print(f"❌ Could not connect to MongoDB: {e}")
        raise SystemExit(1)


def load_destinations(db) -> list[dict]:
    """
    Uses the project's real destinations collection.
    Returns docs with _id, name, city.
    """
    col = db["destinations"]
    docs = list(col.find({}, {"_id": 1, "name": 1, "city": 1}))

    if not docs:
        print("❌ No destinations found in 'destinations' collection.")
        print("Run your real destination seed first before synthetic users.")
        raise SystemExit(1)

    print(f"📍 Loaded {len(docs)} destinations from 'destinations'.")
    return docs


def clear_old_synthetic_data(db) -> None:
    users_col = db["users"]
    reviews_col = db["reviews"]

    deleted_reviews = reviews_col.delete_many({"is_synthetic": True})
    deleted_users = users_col.delete_many({"is_synthetic": True})

    print(
        f"🧹 Cleared old synthetic data: "
        f"{deleted_users.deleted_count} users, "
        f"{deleted_reviews.deleted_count} reviews."
    )


def build_users(n: int = 30) -> list[dict]:
    """
    30 synthetic users:
      - 10 power users
      - 10 active users
      - 10 new users
    """
    first_names = [
        "Norah", "Shadan", "Badoor", "Elaf", "Rehab",
        "Sara", "Mona", "Dana", "Lina", "Reem",
        "Fahad", "Omar", "Khalid", "Abdulrahman", "Faisal",
        "Turki", "Meshal", "Nawaf", "Sultan", "Majed",
        "Hessa", "Noura", "Latifa", "Wedad", "Arwa",
        "Yazeed", "Saud", "Bandar", "Hamad", "Talal",
    ]

    users = []
    for i, name in enumerate(first_names[:n]):
        username = f"{name.lower()}_{random.randint(10, 99)}"
        user = {
            "username": username,
            "name": name,
            "email": f"{username}@terhal.test",
            "password": hash_password(TEST_PASSWORD),
            "created_at": random_date_within_days(365),
            "is_synthetic": True,
            "preferences": {
                "city": random.choice(CITIES),
                "visitor_type": random.choice(VISITOR_TYPES),
                "preferred_time": random.choice(TIMES),
                "mood": random.choice(MOODS),
                "activity": random.choice(ACTIVITIES),
                "budget": random.choice(BUDGETS),
                "environment": random.choice(ENVIRONMENTS),
            },
        }
        users.append(user)

    # Guarantee at least one seeded user per city
    for idx, city in enumerate(CITIES):
        users[idx]["preferences"]["city"] = city

    return users


def build_reviews(users: list[dict], destinations: list[dict]) -> tuple[list[dict], dict]:
    """
    Review distribution:
      - Users 0-9   => Power Users  : 5-10 reviews each
      - Users 10-19 => Active Users : 2-4 reviews each
      - Users 20-29 => New Users    : 0 reviews
    """
    reviews = []
    activity_map = {}

    def make_review(user_id, destination):
        return {
            "user_id": str(user_id),
            "destination_id": destination["name"],  # matches recommender logic
            "dest_object_id": destination["_id"],
            "rating": round(random.uniform(3.0, 5.0) * 2) / 2,
            "comment": random.choice(SAMPLE_COMMENTS),
            "created_at": random_date_within_days(180),
            "is_synthetic": True,
        }

    for idx, user in enumerate(users):
        uid = user["_id"]

        if idx < 10:
            count = random.randint(5, 10)
            sampled = random.sample(destinations, min(count, len(destinations)))
            for dest in sampled:
                reviews.append(make_review(uid, dest))
            activity_map[str(uid)] = ("Power User", user["username"], count)

        elif idx < 20:
            count = random.randint(2, 4)
            sampled = random.sample(destinations, min(count, len(destinations)))
            for dest in sampled:
                reviews.append(make_review(uid, dest))
            activity_map[str(uid)] = ("Active User", user["username"], count)

        else:
            activity_map[str(uid)] = ("New User", user["username"], 0)

    return reviews, activity_map


def insert_synthetic_data(db, users: list[dict], reviews: list[dict]) -> dict:
    users_col = db["users"]
    reviews_col = db["reviews"]

    user_result = users_col.insert_many(users)
    for user, oid in zip(users, user_result.inserted_ids):
        user["_id"] = oid

    print(f"👤 Inserted {len(user_result.inserted_ids)} synthetic users.")

    reviews, activity_map = build_reviews(users, load_destinations(db))

    if reviews:
        review_result = reviews_col.insert_many(reviews)
        print(f"⭐ Inserted {len(review_result.inserted_ids)} synthetic reviews.")
    else:
        print("⚠️ No synthetic reviews were generated.")

    return activity_map


def print_summary(activity_map: dict) -> None:
    print("\n" + "=" * 76)
    print(f"{'TERHAL SYNTHETIC TEST DATA SUMMARY':^76}")
    print("=" * 76)
    print(f"{'User ID':<28} {'Username':<20} {'Type':<14} {'Reviews':>8}")
    print("-" * 76)

    for user_id, (label, username, count) in activity_map.items():
        print(f"{user_id:<28} {username:<20} {label:<14} {count:>8}")

    power = sum(1 for v in activity_map.values() if v[0] == "Power User")
    active = sum(1 for v in activity_map.values() if v[0] == "Active User")
    new = sum(1 for v in activity_map.values() if v[0] == "New User")
    total_reviews = sum(v[2] for v in activity_map.values())

    print("-" * 76)
    print(f"Power Users : {power}")
    print(f"Active Users: {active}")
    print(f"New Users   : {new}")
    print(f"Total Reviews Generated: {total_reviews}")
    print(f"Test password for all synthetic users: {TEST_PASSWORD}")
    print("=" * 76 + "\n")


# =========================================================
# MAIN
# =========================================================
def main():
    print("\n🚀 Starting TERHAL synthetic user/review seed...\n")

    db = connect_to_db()
    clear_old_synthetic_data(db)

    users = build_users(30)

    users_col = db["users"]
    user_result = users_col.insert_many(users)
    print(f"👤 Inserted {len(user_result.inserted_ids)} synthetic users.")

    for user, oid in zip(users, user_result.inserted_ids):
        user["_id"] = oid

    destinations = load_destinations(db)
    reviews, activity_map = build_reviews(users, destinations)

    if reviews:
        reviews_col = db["reviews"]
        review_result = reviews_col.insert_many(reviews)
        print(f"⭐ Inserted {len(review_result.inserted_ids)} synthetic reviews.")
    else:
        print("⚠️ No synthetic reviews were generated.")

    print_summary(activity_map)
    print("✅ Synthetic test data seeded successfully.")


if __name__ == "__main__":
    main()