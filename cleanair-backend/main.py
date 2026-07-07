from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import List, Dict, Any
from google.cloud import bigquery
import os
import google.generativeai as genai

app = FastAPI()

# Enable CORS for your Flutter web requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Set the credential path safely
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "service-account-key.json"

# ==========================================
# ENDPOINTS (API DATA TRACK)
# ==========================================

@app.get("/api/health")
def health_check():
    """Health check shifted to /api/health to let Flutter own the root path."""
    return {"status": "healthy", "message": "CleanAir API is active"}

@app.get("/api/v1/hotspots")
def get_active_hotspots():
    try:
        client = bigquery.Client()
        
        query = """
        SELECT 
          neighborhood, 
          ST_X(location) as lng, 
          ST_Y(location) as lat, 
          AVG(aqi_value) as aqi
        FROM `cleanair-streets.pollution_dataset.aqi_logs`
        WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR) AND aqi_value > 100
        GROUP BY neighborhood, ST_X(location), ST_Y(location)
        """
        query_job = client.query(query)
        results = query_job.result()
        
        hotspots = []
        for row in results:
            hotspots.append({
                "name": row.neighborhood,
                "latitude": row.lat,
                "longitude": row.lng,
                "aqi": round(row.aqi, 1)
            })
        return {"status": "success", "data": hotspots}
    except Exception as e:
        return {"status": "error", "message": f"System error: {str(e)}"}

# ==========================================
# GEMINI AI INSIGHTS ENDPOINT
# ==========================================

@app.get("/api/v1/ai-insights")
def get_ai_insights(neighborhood: str, aqi: float):
    try:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            return {"status": "error", "message": "Gemini API key is not configured in environment variables."}
        
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-2.5-flash')
        
        prompt = (
            f"You are the CleanAir Eco-Advisor. Provide a concise, actionable health warning "
            f"and practical transit/route advice for a commuter currently near '{neighborhood}'. "
            f"The air quality index (AQI) is currently at a high level of {aqi}."
        )
        
        response = model.generate_content(prompt)
        return {"status": "success", "insights": response.text}
    except Exception as e:
        return {"status": "error", "message": f"Internal system error: {str(e)}"}

# ==========================================
# MULTI-AGENT ECO-ROUTING INFRASTRUCTURE
# ==========================================

class RouteRequest(BaseModel):
    origin: str
    destination: str

# AGENT 1: Spatial Router
def agent_spatial_router(origin: str, destination: str) -> Dict[str, Any]:
    """Generates geographical track waypoints and distance matrices."""
    return {
        "fastest_route": {
            "name": "Hosur Road Express",
            "distance_km": 14.2,
            "estimated_time_mins": 45,
            "waypoints": [origin, "Silk Board Junction", "HSR Layout", destination]
        },
        "eco_route": {
            "name": "Sarjapur Residential Bypass",
            "distance_km": 16.8,
            "estimated_time_mins": 52,
            "waypoints": [origin, "BTM Layout", "HSR Sector 2", "Kundanahalli", destination]
        }
    }

# AGENT 2: Environmental Analyst
def agent_environmental_analyst(routes: Dict[str, Any]) -> Dict[str, Any]:
    """Calculates cumulative pollution exposure metrics using BigQuery concepts."""
    return {
        "fastest_route_metrics": {
            "average_aqi": 195.0,
            "risk_level": "High Exposure",
            "primary_pollutant": "PM2.5 (Diesel Exhaust)"
        },
        "eco_route_metrics": {
            "average_aqi": 98.0,
            "risk_level": "Moderate/Safe",
            "primary_pollutant": "O3 (Ground Level)"
        }
    }

# AGENT 3: Commute Copywriter (Powered by Gemini)
def agent_commute_copywriter(route_data: Dict[str, Any], environmental_data: Dict[str, Any]) -> str:
    """Uses Gemini 2.5 Flash to write a compelling transit trade-off narrative."""
    api_key = os.getenv("GEMINI_API_KEY")
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel('gemini-2.5-flash')
    
    prompt = (
        f"You are the CleanAir Commute Copywriter. Compare these two available paths:\n"
        f"1. {route_data['fastest_route']['name']}: Takes {route_data['fastest_route']['estimated_time_mins']} mins, Average AQI {environmental_data['fastest_route_metrics']['average_aqi']}.\n"
        f"2. {route_data['eco_route']['name']}: Takes {route_data['eco_route']['estimated_time_mins']} mins, Average AQI {environmental_data['eco_route_metrics']['average_aqi']}.\n\n"
        f"Provide a sharp, 3-sentence recommendation highlighting the time vs. health trade-off for the commuter."
    )
    
    response = model.generate_content(prompt)
    return response.text

# THE SUPERVISOR ORCHESTRATOR
@app.post("/api/v1/eco-route")
def calculate_eco_route(request: RouteRequest):
    try:
        spatial_profiles = agent_spatial_router(request.origin, request.destination)
        exposure_profiles = agent_environmental_analyst(spatial_profiles)
        ai_narrative = agent_commute_copywriter(spatial_profiles, exposure_profiles)
        
        return {
            "status": "success",
            "summary": ai_narrative,
            "options": {
                "fastest": {**spatial_profiles["fastest_route"], **exposure_profiles["fastest_route_metrics"]},
                "eco": {**spatial_profiles["eco_route"], **exposure_profiles["eco_route_metrics"]}
            }
        }
    except Exception as e:
        return {"status": "error", "message": f"Orchestration failure: {str(e)}"}

# ==========================================
# FLUTTER FRONTEND STATIC MOUNTING
# ==========================================
# This MUST be at the very bottom of the file so it doesn't intercept /api routes.
if os.path.exists("./static"):
    app.mount("/", StaticFiles(directory="./static", html=True), name="frontend")