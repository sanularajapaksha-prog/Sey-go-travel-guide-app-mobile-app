import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from supabase import Client, create_client

_ENV_PATH = Path(__file__).resolve().parent.parent / '.env'
load_dotenv(dotenv_path=_ENV_PATH)

security = HTTPBearer()


def get_supabase_client() -> Client:
    """
    Creates a fresh Supabase client on every call.
    
    NOTE: Do NOT use @lru_cache here. The Supabase Python client stores
    an internal PostgREST JWT that expires after 1 hour. Caching the client
    object would cause PGRST303 (JWT expired) errors on all subsequent
    requests after the first hour of server uptime.
    """
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
            detail='Invalid or expired token.',
        ) from exc
        
