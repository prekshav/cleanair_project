CleanAir Platform

CleanAir is an intelligent, serverless multi-agent routing and municipal intervention ecosystem designed to protect commuters from urban pollution hotspots.

Overview

The platform fuses real-time BigQuery spatial analytics, satellite imagery, and citizen uploads with Gemini 2.5 Flash to map hyper-local neighborhood hotspots and dispatch municipal resources where needed.

Architecture

Backend: FastAPI (Python 3.11)

Frontend: Flutter Web (compiled and served statically)

Data Lake: Google BigQuery (Geospatial GIS layers)

AI Engine: Vertex AI (Gemini 2.5 Flash)

Infrastructure: Google Cloud Run (Serverless, scale-to-zero)

Key Features

Spatial Hotspot Isolation: Uses BigQuery GIS to identify local AQI anomalies in sub-350ms.

Multi-Agent Orchestrator: Concurrent asynchronous agents handle spatial mapping and environmental monitoring.

Eco-Advisor: Uses Gemini 2.5 Flash to provide conversational, empathetic route safety advice.

Unified Deployment: Single-container serverless architecture for zero-cold-start performance.

Getting Started

API Setup: Ensure your GEMINI_API_KEY is set in the environment variables.

Database: Verify GOOGLE_APPLICATION_CREDENTIALS points to your service account key.

Deployment: Use the deploy.sh script to build the Flutter web assets and deploy the backend container to Google Cloud Run.

API Endpoints

GET /api/health - System health check.

GET /api/v1/hotspots - Retrieves current active pollution hotspots.

POST /api/v1/eco-route - Calculates multi-agent eco-route recommendations.