from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routers import auth
from .routers import places
from .routers import playlists
from .routers import route
from .routers import users

app = FastAPI(title='SeyGo Backend')

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


@app.get('/health')
async def health_check():
    return {'status': 'ok'}
