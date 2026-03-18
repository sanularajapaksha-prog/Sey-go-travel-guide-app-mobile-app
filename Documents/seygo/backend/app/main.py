from __future__ import annotations

import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routers import auth, places, playlists, route, users
from .routers import search as search_router

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Startup: warm up the semantic index so the first search is instant.
    The model (~118 MB) is downloaded once and cached by sentence-transformers.
    Index is built from Supabase and persisted to ml_models/ on disk.
    Subsequent restarts load from disk in ~1 second.
    """
    import asyncio

    def _warmup():
        try:
            from supabase import create_client as _cc
            sb = _cc(
                os.environ['SUPABASE_URL'],
                os.environ['SUPABASE_SERVICE_ROLE_KEY'],
            )
            from .services.semantic_recommender import semantic_recommender
            semantic_recommender.ensure_ready(sb)
            logger.info('Semantic index ready.')
        except Exception as exc:
            logger.warning('Semantic warmup failed (non-fatal): %s', exc)

    loop = asyncio.get_event_loop()
    loop.run_in_executor(None, _warmup)

    yield  # server runs here


app = FastAPI(title='SeyGo Backend', lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)

app.include_router(places.router)
app.include_router(auth.router)
app.include_router(playlists.router)
app.include_router(route.router)
app.include_router(users.router)
app.include_router(search_router.router)


@app.get('/health')
async def health_check():
    from .services.semantic_recommender import semantic_recommender
    return {
        'status': 'ok',
        'semantic_index': semantic_recommender.index_info(),
    }
