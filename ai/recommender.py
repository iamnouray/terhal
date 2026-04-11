import pandas as pd
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import MultiLabelBinarizer
from database import destinations_collection, reviews_collection
import math
import re

# ─────────────────────────────────────────
# CACHE — loads places once, not every request
# ─────────────────────────────────────────
_cached_places = None

def _get_all_places():
    global _cached_places
    if _cached_places is None:
        _cached_places = list(destinations_collection.find({}, {"_id": 0}))
    return _cached_places

# ─────────────────────────────────────────
# SURVEY MAPPINGS
# ─────────────────────────────────────────

MOOD_TAG_MAP = {
    "adventurous":  ["outdoor", "adventure", "hiking", "sports", "scenic"],
    "relaxed":      ["cozy", "quiet", "park", "nature", "calm", "spa"],
    "energetic":    ["entertainment", "active", "sports", "shopping", "events"],
    "calm & quiet": ["nature", "park", "quiet", "scenic", "museum"],
}

ACTIVITY_CATEGORY_MAP = {
    "breakfast":            ["cafe", "restaurant"],
    "lunch / dinner":       ["restaurant"],
    "coffee":               ["cafe"],
    "shopping":             ["shopping"],
    "scenic drive & views": ["park", "attraction"],
}

BUDGET_MAP = {
    "$":   ["$"],
    "$$":  ["$", "$$"],
    "$$$": ["$", "$$", "$$$"],
}

GROUP_MAP = {
    "solo":    "solo",
    "friends": "friends",
    "family":  "family",
    "couple":  "couples",
}

CITY_MAP = {
    "madinah": "Madinah",
    "jeddah":  "Jeddah",
    "riyadh":  "Riyadh",
    "alula":   "AlUla",
    "abha":    "Abha",
}

TIME_MAP = {
    "morning":    "Morning",
    "afternoon":  "Afternoon",
    "evening":    "Evening",
    "late night": "Late Night",
}

# Scoring weights
CITY_BOOST     = 5.0
GROUP_BOOST    = 3.0
TIME_BOOST     = 3.0
ACTIVITY_BOOST = 2.5
BUDGET_BOOST   = 2.0
MOOD_BOOST     = 1.5

SIMILARITY_WEIGHT = 0.5
QUALITY_WEIGHT    = 0.3
SURVEY_WEIGHT     = 0.2

NEW_USER_QUALITY_WEIGHT = 0.6
NEW_USER_SURVEY_WEIGHT  = 0.4

# ─────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────

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

    df = df.copy()
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


def _normalize_survey(survey: dict) -> dict:
    normalized = dict(survey)
    raw_city  = (survey.get("city") or "").lower().strip()
    normalized["city"] = CITY_MAP.get(raw_city, survey.get("city"))
    raw_group = (survey.get("visitor_type") or "").lower().strip()
    normalized["visitor_type"] = GROUP_MAP.get(raw_group, survey.get("visitor_type"))
    raw_time  = (survey.get("preferred_time") or "").lower().strip()
    normalized["preferred_time"] = TIME_MAP.get(raw_time, survey.get("preferred_time"))
    return normalized


def _apply_survey_boost(df: pd.DataFrame, survey: dict) -> pd.Series:
    boost = pd.Series(0.0, index=df.index)

    mood = (survey.get("mood") or "").lower().strip()
    mood_keywords = MOOD_TAG_MAP.get(mood, [])
    if mood_keywords:
        tags_col = df.get("tags", pd.Series("", index=df.index)).fillna("").str.lower()
        for kw in mood_keywords:
            boost += tags_col.str.contains(kw, na=False).astype(float) * MOOD_BOOST

    activity = (survey.get("activity") or "").lower().strip()
    target_cats = ACTIVITY_CATEGORY_MAP.get(activity, [])
    if target_cats:
        cat_col = df.get("category", pd.Series("", index=df.index)).fillna("").str.lower()
        sub_col = df.get("subtypes", pd.Series("", index=df.index)).fillna("").str.lower()
        for cat in target_cats:
            boost += (
                cat_col.str.contains(cat, na=False) |
                sub_col.str.contains(cat, na=False)
            ).astype(float) * ACTIVITY_BOOST

    group = (survey.get("visitor_type") or "").lower().strip()
    if group:
        visitor_col = df.get("visitor_type", pd.Series("", index=df.index)).fillna("").str.lower()
        boost += visitor_col.str.contains(group, na=False).astype(float) * GROUP_BOOST

    time_pref = (survey.get("preferred_time") or "").lower().strip()
    if time_pref:
        time_col = df.get("preferred_time", pd.Series("", index=df.index)).fillna("").str.lower()
        boost += time_col.str.contains(time_pref, na=False).astype(float) * TIME_BOOST

    budget = (survey.get("budget") or "").strip()
    allowed = BUDGET_MAP.get(budget, [])
    if allowed:
        price_col = df.get("prices", pd.Series("", index=df.index)).fillna("").str.strip()
        boost += price_col.isin(allowed).astype(float) * BUDGET_BOOST

    city = (survey.get("city") or "").strip()
    if city:
        city_col = df.get("city", pd.Series("", index=df.index)).fillna("")
        boost += (city_col.str.lower() == city.lower()).astype(float) * CITY_BOOST

    return boost


# ─────────────────────────────────────────
# MAIN FUNCTION
# ─────────────────────────────────────────

def get_recommendations(
    user_id: str,
    survey: dict = None,
    top_n: int = 10,
    city: str = None,
    visitor_type: str = None,
    preferred_time: str = None,
    environment: str = None,
    budget: str = None,
):
    if survey is None:
        survey = {}

    # Load from cache — fast after first request
    all_places = _get_all_places()
    if not all_places:
        return []

    df = pd.DataFrame(all_places).reset_index(drop=True)

    # Normalize survey answers
    survey = _normalize_survey(survey)

    # Pull values from survey if not passed directly
    city           = city           or survey.get("city")
    visitor_type   = visitor_type   or survey.get("visitor_type")
    preferred_time = preferred_time or survey.get("preferred_time")
    budget         = budget         or survey.get("budget")

    # ── STEP 1: Context Filtering ─────────────────────────────────
    filtered = df.copy()

    if city:
        tmp = filtered[filtered["city"].str.lower() == city.lower()]
        if not tmp.empty:
            filtered = tmp

    if visitor_type:
        tmp = filtered[
            filtered["visitor_type"].str.contains(visitor_type, case=False, na=False)
        ]
        if not tmp.empty:
            filtered = tmp

    if preferred_time:
        tmp = filtered[
            filtered["preferred_time"].str.contains(preferred_time, case=False, na=False)
        ]
        if not tmp.empty:
            filtered = tmp

    if environment:
        tmp = filtered[
            filtered["environment"].str.contains(environment, case=False, na=False)
        ]
        if not tmp.empty:
            filtered = tmp

    if budget:
        tmp = filtered[
            filtered["prices"].str.contains(re.escape(budget), case=False, na=False)
        ]
        if not tmp.empty:
            filtered = tmp

    if len(filtered) < top_n:
        filtered = df[df["city"].str.lower() == city.lower()] if city else df.copy()
    if len(filtered) < top_n:
        filtered = df.copy()

    filtered = filtered.reset_index(drop=True)

    # ── STEP 2: Remove visited places ────────────────────────────
    user_reviews = list(reviews_collection.find({"user_id": user_id}))
    visited_names = [r["destination_id"] for r in user_reviews]
    if visited_names:
        filtered = filtered[~filtered["name"].isin(visited_names)].reset_index(drop=True)
    if filtered.empty:
        filtered = df.copy().reset_index(drop=True)

    # ── STEP 3: Survey boost scores ──────────────────────────────
    survey_boost = _apply_survey_boost(filtered, survey)

    # ── STEP 4: Cosine similarity (returning users) ───────────────
    liked_reviews = [r for r in user_reviews if r.get("rating", 0) >= 4]

    if liked_reviews:
        liked_names  = [r["destination_id"] for r in liked_reviews]
        liked_places = df[df["name"].isin(liked_names)].reset_index(drop=True)

        if not liked_places.empty:
            combined       = pd.concat([filtered, liked_places], ignore_index=True)
            feature_matrix = build_feature_matrix(combined)

            n_filtered        = len(filtered)
            filtered_features = feature_matrix.iloc[:n_filtered].values
            liked_features    = feature_matrix.iloc[n_filtered:].values

            user_profile = liked_features.mean(axis=0).reshape(1, -1)
            similarities = cosine_similarity(user_profile, filtered_features)[0]

            filtered = filtered.copy()
            filtered["similarity_score"] = similarities
            filtered["weighted_rating"]  = filtered.apply(
                lambda r: weighted_score(r.get("rating", 0), r.get("reviews", 0)), axis=1
            )
            filtered["survey_boost"] = survey_boost.values

            for col in ["similarity_score", "weighted_rating", "survey_boost"]:
                if filtered[col].max() > 0:
                    filtered[col] = filtered[col] / filtered[col].max()

            filtered["final_score"] = (
                SIMILARITY_WEIGHT * filtered["similarity_score"] +
                QUALITY_WEIGHT    * filtered["weighted_rating"]  +
                SURVEY_WEIGHT     * filtered["survey_boost"]
            )

            fav_category = (
                liked_places["category"].mode()[0]
                if "category" in liked_places.columns
                else None
            )
            if fav_category:
                fav_pool   = filtered[
                    filtered["category"] == fav_category
                ].nlargest(int(top_n * 0.7) + 1, "final_score")
                other_pool = filtered[
                    filtered["category"] != fav_category
                ].nlargest(int(top_n * 0.3) + 1, "final_score")
                top_pool   = pd.concat([fav_pool, other_pool])
            else:
                top_pool = filtered.nlargest(min(top_n * 2, len(filtered)), "final_score")

            result = top_pool.sample(frac=1, random_state=None).head(top_n)
            result = result.drop(
                columns=["similarity_score", "weighted_rating", "final_score",
                         "survey_boost", "time_clean"],
                errors="ignore"
            )
            return result.to_dict(orient="records")

    # ── STEP 5: New user fallback ─────────────────────────────────
    filtered = filtered.copy()
    filtered["weighted_rating"] = filtered.apply(
        lambda r: weighted_score(r.get("rating", 0), r.get("reviews", 0)), axis=1
    )
    filtered["survey_boost"] = survey_boost.values

    for col in ["weighted_rating", "survey_boost"]:
        if filtered[col].max() > 0:
            filtered[col] = filtered[col] / filtered[col].max()

    filtered["final_score"] = (
        NEW_USER_QUALITY_WEIGHT * filtered["weighted_rating"] +
        NEW_USER_SURVEY_WEIGHT  * filtered["survey_boost"]
    )

    top_pool = filtered.nlargest(min(top_n * 3, len(filtered)), "final_score")
    result   = top_pool.sample(frac=1, random_state=None).head(top_n)
    result   = result.drop(
        columns=["weighted_rating", "survey_boost", "final_score", "time_clean"],
        errors="ignore"
    )
    return result.to_dict(orient="records")


# Backward compatibility alias
get_personalized_recommendations = get_recommendations