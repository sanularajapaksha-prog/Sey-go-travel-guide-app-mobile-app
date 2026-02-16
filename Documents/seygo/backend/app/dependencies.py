import os
from functools import lru_cache

from dotenv import load_dotenv
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from supabase import Client, create_client

load_dotenv()

security = HTTPBearer()


@lru_cache
def get_supabase_client() -> Client:
    url = os.getenv('SUPABASE_URL', '')
    service_role_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY', '')

    if not url or not service_role_key:
        raise RuntimeError(
            'SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required.'
        )

    return create_client(url, service_role_key)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
):
    token = credentials.credentials
    supabase = get_supabase_client()

    try:
        response = supabase.auth.get_user(token)
        user = getattr(response, 'user', None)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail='Invalid token.',
            )
        return user
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f'Authentication failed: {exc}',
        ) from exc
