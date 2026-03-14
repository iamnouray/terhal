import pandas as pd
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from database import destinations_collection

def seed():
    df = pd.read_excel("Smart_Guide_V5_Final.xlsx")
    data = df.to_dict(orient="records")
    destinations_collection.delete_many({})
    destinations_collection.insert_many(data)
    print(f"✅ تم رفع {len(data)} مكان لـ MongoDB")

seed()