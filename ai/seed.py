import pandas as pd
import sys
import os
import json
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from database import destinations_collection

def seed():
    df = pd.read_excel("Smart_Guide_V5_Final.xlsx", sheet_name="All Data")
    df['cid'] = df['cid'].astype(str)
    df = df.where(pd.notnull(df), None)
    data = json.loads(df.to_json(orient="records"))
    destinations_collection.delete_many({})
    destinations_collection.insert_many(data)
    print(f"✅ تم رفع {len(data)} مكان لـ MongoDB")

seed()