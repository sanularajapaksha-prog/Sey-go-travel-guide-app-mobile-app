"""
search.py
=========
POST /search  — Main semantic search endpoint for the SeyGo mobile app.

Full pipeline per request:
  1. Parse intent (category + location + radius from free text)
  2. Geocode detected location → (lat, lng) center
  3. Semantic vector search + radius filter + ranking
  4. Fallback: expand radius ×3 if fewer than 3 results
  5. Fallback: pure semantic (no radius) if still empty
  6. Return ranked results + map metadata (center, radius circle)
"""

from __future__ import annotations

import os
import logging
from typing import Optional

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from ..services.semantic_recommender import (
    semantic_recommender,
    parse_intent,
    geocode_location,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix='/search', tags=['search'])


# ---------------------------------------------------------------------------
# Request / Response schemas
# ---------------------------------------------------------------------------

class SearchRequest(BaseModel):
    query: str = Field(min_length=1, max_length=300,
                       description='Free-text query in any language')
    latitude:  Optional[float] = Field(default=None,
                                       description="User's current lat (optional)")
    longitude: Optional[float] = Field(default=None,
                                       description="User's current lng (optional)")
    radius_km: float = Field(default=10.0, ge=0.5, le=200.0,
                             description='Search radius in km')
    top_n: int = Field(default=20, ge=1, le=100,
                       description='Max results to return')


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_supabase():
    from supabase import create_client as _cc
    return _cc(
        os.environ['SUPABASE_URL'],
        os.environ['SUPABASE_SERVICE_ROLE_KEY'],
    )


def _format_result(r: dict) -> dict:
    return {
        'place_id':         str(r.get('place_id') or r.get('id') or ''),
        'name':             str(r.get('name') or ''),
        'category':         str(r.get('primary_category') or r.get('category') or ''),
        'taxonomy_category': r.get('taxonomy_category') or '',
        'taxonomy_group':    r.get('taxonomy_group') or '',
        'latitude':         r.get('_lat'),
        'longitude':        r.get('_lng'),
        'avg_rating':       float(r.get('avg_rating') or r.get('rating') or 0),
        'review_count':     int(r.get('review_count') or r.get('reviews') or 0),
        'description':      str(r.get('description') or ''),
        'location':         str(r.get('location') or ''),
        'google_url':       r.get('google_url') or None,
        'image_url':        r.get('image_url') or None,
        'dist_km':          r.get('_dist_km'),
        'score':            r.get('_score'),
        'semantic_score':   r.get('_semantic'),
        'category_boosted': r.get('_category_boosted', False),
    }


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.post('/')
def semantic_search(req: SearchRequest):
    """
    Semantic place search with radius filtering and intent detection.

    Examples:
      { "query": "best cafe near Yakkala", "radius_km": 5 }
      { "query": "temple near Kandy", "radius_km": 10 }
      { "query": "garden in Gampaha" }
      { "query": "Kurunegala" }
      { "query": "historical place around Anuradhapura", "radius_km": 20 }
    """
    try:
        sb = _make_supabase()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f'DB connection failed: {exc}',
        )

    # 1. Parse intent
    intent             = parse_intent(req.query)
    detected_category  = intent['detected_category']
    detected_location  = intent['detected_location']
    radius_km          = intent['radius_km'] or req.radius_km

    # 2. Determine center
    center_lat: Optional[float] = req.latitude
    center_lng: Optional[float] = req.longitude
    center_name: Optional[str]  = None

    if detected_location:
        coords = geocode_location(detected_location)
        if coords:
            center_lat, center_lng = coords
            center_name = detected_location
            logger.info('Geocoded "%s" → (%.4f, %.4f)', detected_location, center_lat, center_lng)

    # 3. Primary search
    semantic_recommender.ensure_ready(sb)

    results = semantic_recommender.search(
        sb,
        query=req.query,
        center_lat=center_lat,
        center_lng=center_lng,
        radius_km=radius_km,
        top_n=req.top_n,
        detected_category=detected_category,
    )

    # 4. Fallback: expand radius ×3 if fewer than 3 results
    if len(results) < 3 and center_lat is not None:
        expanded = radius_km * 3
        results   = semantic_recommender.search(
            sb,
            query=req.query,
            center_lat=center_lat,
            center_lng=center_lng,
            radius_km=expanded,
            top_n=req.top_n,
            detected_category=detected_category,
        )
        if results:
            radius_km = expanded

    # 5. Fallback: pure semantic — no geographic filter
    if not results:
        results = semantic_recommender.search(
            sb,
            query=req.query,
            center_lat=None,
            center_lng=None,
            radius_km=radius_km,
            top_n=req.top_n,
            detected_category=detected_category,
        )

    # 6. Confidence flag
    top_semantic   = results[0].get('_semantic', 1.0) if results else 1.0
    low_confidence = top_semantic < 0.20

    return {
        'query':              req.query,
        'detected_category':  detected_category,
        'detected_location':  detected_location,
        'center': (
            {'lat': center_lat, 'lng': center_lng}
            if center_lat is not None else None
        ),
        'center_name':        center_name,
        'radius_km':          radius_km,
        'count':              len(results),
        'low_confidence':     low_confidence,
        'results':            [_format_result(r) for r in results],
    }


@router.get('/status')
def search_status():
    """Returns whether the semantic index is ready and its size."""
    return semantic_recommender.index_info()


@router.post('/rebuild')
def rebuild_index():
    """
    Force a full semantic index rebuild from Supabase.
    Takes ~2 minutes for 4900+ places. Call after bulk imports.
    """
    try:
        sb = _make_supabase()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f'DB connection failed: {exc}',
        )
    return semantic_recommender.rebuild(sb)
