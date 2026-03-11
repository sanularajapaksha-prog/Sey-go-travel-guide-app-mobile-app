from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routers import places

app = FastAPI(title='SeyGo Backend')

app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)

app.include_router(places.router)


@app.get('/health')
async def health_check():
    return {'status': 'ok'}
