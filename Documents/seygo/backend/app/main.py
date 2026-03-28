from __future__ import annotations

import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from dotenv import load_dotenv

load_dotenv()

limiter = Limiter(key_func=get_remote_address)

from .routers import auth, places, playlists, route, users
from .routers import search as search_router
from .routers import reviews as reviews_router
from .routers import destinations as destinations_router
from .routers import notifications as notifications_router

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Startup: optionally warm up the semantic index.
    Set SEMANTIC_ENABLED=true to enable (requires sentence-transformers installed).
    Disabled by default to keep memory within Railway free-tier limits.
    """
    if os.getenv('SEMANTIC_ENABLED', 'false').lower() == 'true':
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
    else:
        logger.info('Semantic search disabled (SEMANTIC_ENABLED != true). Using keyword search.')

    yield  # server runs here


app = FastAPI(title='SeyGo Backend', lifespan=lifespan)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

_raw_origins = os.getenv('ALLOWED_ORIGINS', '')
_allowed_origins: list[str] = (
    [o.strip() for o in _raw_origins.split(',') if o.strip()]
    if _raw_origins
    else ['http://localhost:3000', 'http://10.0.2.2:8000']
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed_origins,
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
app.include_router(reviews_router.router)
app.include_router(destinations_router.router)
app.include_router(notifications_router.router)

@app.get('/health')
async def health_check():
    semantic_enabled = os.getenv('SEMANTIC_ENABLED', 'false').lower() == 'true'
    info: dict = {'ready': False, 'mode': 'keyword'}
    if semantic_enabled:
        try:
            from .services.semantic_recommender import semantic_recommender
            info = semantic_recommender.index_info()
            info['mode'] = 'semantic'
        except Exception:
            pass
    return {'status': 'ok', 'semantic_index': info}
