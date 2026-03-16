import pandas as pd
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import MultiLabelBinarizer
from database import destinations_collection, reviews_collection
import math
import re

def extract_time_keywords(time_str):
    if not time_str or pd.isna(time_str):
        return ""
    keywords = ["Morning", "Afternoon", "Evening", "Night", "Late Night", "Noon"]
    found = [k for k in keywords if k.lower() in str(time_str).lower()]
    return ", ".join(found)

def weighted_score(rating, review_count):
    if review_count == 0:
        return 0
    return float(rating) * math.log(float(review_count) + 1)

def build_feature_matrix(df):
    features = pd.DataFrame()
    features["weighted_score"] = df.apply(
        lambda r: weighted_score(r.get("rating", 0), r.get("reviews", 0)), axis=1
    )
    cat_dummies = pd.get_dummies(df["category"].fillna("unknown"), prefix="cat")
    features = pd.concat([features, cat_dummies], axis=1)
    env_dummies = pd.get_dummies(df["environment"].fillna("unknown"), prefix="env")
    features = pd.concat([features, env_dummies], axis=1)
    price_dummies = pd.get_dummies(df["prices"].fillna("unknown"), prefix="price")
    features = pd.concat([features, price_dummies], axis=1)
    visitor_lists = df["visitor_type"].fillna("").apply(
        lambda x: [v.strip() for v in str(x).split(",") if v.strip()]
    )
    mlb_visitor = MultiLabelBinarizer()
    visitor_encoded = pd.DataFrame(
        mlb_visitor.fit_transform(visitor_lists),
        columns=[f"visitor_{c}" for c in mlb_visitor.classes_],
        index=df.index
    )
    features = pd.concat([features, visitor_encoded], axis=1)
    df["time_clean"] = df["preferred_time"].apply(extract_time_keywords)
    time_lists = df["time_clean"].apply(
        lambda x: [t.strip() for t in str(x).split(",") if t.strip()]
    )
    mlb_time = MultiLabelBinarizer()
    time_encoded = pd.DataFrame(
        mlb_time.fit_transform(time_lists),
        columns=[f"time_{c}" for c in mlb_time.classes_],
        index=df.index
    )
    features = pd.concat([features, time_encoded], axis=1)
    return features.fillna(0).astype(float)

def get_recommendations(
    user_id: str,
    top_n: int = 5,
    city: str = None,
    visitor_type: str = None,
    preferred_time: str = None,
    environment: str = None,
    budget: str = None
):
    all_places = list(destinations_collection.find({}, {"_id": 0}))
    if not all_places:
        return []

    df = pd.DataFrame(all_places)
    df = df.reset_index(drop=True)

    filtered = df.copy()

    if city:
        city_filtered = filtered[filtered["city"].str.lower() == city.lower()]
        if not city_filtered.empty:
            filtered = city_filtered

    if visitor_type:
        vt_filtered = filtered[
            filtered["visitor_type"].str.contains(visitor_type, case=False, na=False)
        ]
        if not vt_filtered.empty:
            filtered = vt_filtered

    if preferred_time:
        time_filtered = filtered[
            filtered["preferred_time"].str.contains(preferred_time, case=False, na=False)
        ]
        if not time_filtered.empty:
            filtered = time_filtered

    if environment:
        env_filtered = filtered[
            filtered["environment"].str.contains(environment, case=False, na=False)
        ]
        if not env_filtered.empty:
            filtered = env_filtered

    if budget:
        budget_filtered = filtered[
            filtered["prices"].str.contains(re.escape(budget), case=False, na=False)
        ]
        if not budget_filtered.empty:
            filtered = budget_filtered

    if len(filtered) < top_n:
        if city:
            filtered = df[df["city"].str.lower() == city.lower()]
        if len(filtered) < top_n:
            filtered = df.copy()

    filtered = filtered.reset_index(drop=True)

    user_reviews = list(reviews_collection.find({"user_id": user_id}))
    visited_names = [r["destination_id"] for r in user_reviews]

    if visited_names:
        filtered = filtered[~filtered["name"].isin(visited_names)]
        filtered = filtered.reset_index(drop=True)

    if filtered.empty:
        filtered = df.copy()
        filtered = filtered.reset_index(drop=True)

    liked_reviews = [r for r in user_reviews if r.get("rating", 0) >= 4]

    if liked_reviews:
        liked_names = [r["destination_id"] for r in liked_reviews]
        liked_places = df[df["name"].isin(liked_names)].reset_index(drop=True)

        if not liked_places.empty:
            combined = pd.concat([filtered, liked_places], ignore_index=True)
            feature_matrix = build_feature_matrix(combined)

            n_filtered = len(filtered)
            n_liked = len(liked_places)

            filtered_features = feature_matrix.iloc[:n_filtered].values
            liked_features = feature_matrix.iloc[n_filtered:].values

            user_profile = liked_features.mean(axis=0).reshape(1, -1)
            similarities = cosine_similarity(user_profile, filtered_features)[0]

            filtered = filtered.copy()
            filtered["similarity_score"] = similarities
            filtered["weighted_rating"] = filtered.apply(
                lambda r: weighted_score(r.get("rating", 0), r.get("reviews", 0)), axis=1
            )

            if filtered["similarity_score"].max() > 0:
                filtered["similarity_score"] = (
                    filtered["similarity_score"] / filtered["similarity_score"].max()
                )
            if filtered["weighted_rating"].max() > 0:
                filtered["weighted_rating"] = (
                    filtered["weighted_rating"] / filtered["weighted_rating"].max()
                )

            filtered["final_score"] = (
                0.6 * filtered["similarity_score"] +
                0.4 * filtered["weighted_rating"]
            )

            fav_category = liked_places["category"].mode()[0] if "category" in liked_places.columns else None

            if fav_category:
                fav_pool = filtered[filtered["category"] == fav_category].nlargest(
                    int(top_n * 0.7) + 1, "final_score"
                )
                other_pool = filtered[filtered["category"] != fav_category].nlargest(
                    int(top_n * 0.3) + 1, "final_score"
                )
                top_pool = pd.concat([fav_pool, other_pool])
            else:
                top_pool = filtered.nlargest(min(top_n * 2, len(filtered)), "final_score")

            result = top_pool.sample(frac=1, random_state=None).head(top_n)
            result = result.drop(
                columns=["similarity_score", "weighted_rating", "final_score", "time_clean"],
                errors="ignore"
            )
            return result.to_dict(orient="records")

    filtered["weighted_rating"] = filtered.apply(
        lambda r: weighted_score(r.get("rating", 0), r.get("reviews", 0)), axis=1
    )
    top_pool = filtered.nlargest(min(top_n * 3, len(filtered)), "weighted_rating")
    result = top_pool.sample(frac=1, random_state=None).head(top_n)
    result = result.drop(columns=["weighted_rating", "time_clean"], errors="ignore")
    return result.to_dict(orient="records")