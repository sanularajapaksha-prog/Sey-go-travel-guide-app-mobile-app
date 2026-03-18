from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, EmailStr, Field

from ..dependencies import get_supabase_client

router = APIRouter(prefix='/auth', tags=['auth'])


class RegisterRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class LoginOtpRequest(BaseModel):
    email: EmailStr


class VerifyLoginOtpRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=8)


class ResendVerificationRequest(BaseModel):
    email: EmailStr


class VerifyOtpRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=8)


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    access_token: str = Field(min_length=1)
    refresh_token: str = Field(min_length=1)
    new_password: str = Field(min_length=6, max_length=128)


def _resend_signup_verification(supabase, email: str) -> bool:
    try:
        supabase.auth.resend(
            {
                'type': 'signup',
                'email': email,
            }
        )
        return True
    except Exception:
        return False


@router.post('/register')
async def register(payload: RegisterRequest):
    try:
        supabase = get_supabase_client()
        normalized_email = payload.email.lower().strip()
        result = supabase.auth.sign_up(
            {
                'email': normalized_email,
                'password': payload.password,
                'options': {
                    'data': {'full_name': payload.full_name.strip()},
                },
            }
        )
        user = getattr(result, 'user', None)
        session = getattr(result, 'session', None)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail='Registration failed.',
            )

        verification_sent = _resend_signup_verification(supabase, normalized_email)

        return {
            'message': 'Registration successful.',
            'user_id': str(getattr(user, 'id', '')),
            'email': str(getattr(user, 'email', payload.email)),
            'requires_email_confirmation': session is None,
            'verification_email_sent': verification_sent or session is None,
            'access_token': getattr(session, 'access_token', None) if session else None,
            'refresh_token': getattr(session, 'refresh_token', None) if session else None,
        }
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f'Failed to register user: {exc}',
        ) from exc


@router.post('/login')
async def login(payload: LoginRequest):
    try:
        supabase = get_supabase_client()
        result = supabase.auth.sign_in_with_password(
            {
                'email': payload.email.lower().strip(),
                'password': payload.password,
            }
        )
        user = getattr(result, 'user', None)
        session = getattr(result, 'session', None)
        if not user or not session:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail='Invalid credentials.',
            )

        return {
            'message': 'Login successful.',
            'user_id': str(getattr(user, 'id', '')),
            'email': str(getattr(user, 'email', payload.email)),
            'access_token': getattr(session, 'access_token', None),
            'refresh_token': getattr(session, 'refresh_token', None),
        }
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f'Failed to login: {exc}',
        ) from exc


@router.post('/login/send-otp')
async def send_login_otp(payload: LoginOtpRequest):
    try:
        supabase = get_supabase_client()
        supabase.auth.sign_in_with_otp(
            {
                'email': payload.email.lower().strip(),
                'create_user': False,
            }
        )
        return {'message': 'Login code sent.'}
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f'Failed to send login code: {exc}',
        ) from exc


@router.post('/login/verify-otp')
async def verify_login_otp(payload: VerifyLoginOtpRequest):
    try:
        supabase = get_supabase_client()
        result = supabase.auth.verify_otp(
            {
                'type': 'email',
                'email': payload.email.lower().strip(),
                'token': payload.code.strip(),
            }
        )
        user = getattr(result, 'user', None)
        session = getattr(result, 'session', None)
        if not user or not session:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail='Invalid code.',
            )

        return {
            'message': 'Login successful.',
            'user_id': str(getattr(user, 'id', '')),
            'email': str(getattr(user, 'email', payload.email)),
            'access_token': getattr(session, 'access_token', None),
            'refresh_token': getattr(session, 'refresh_token', None),
        }
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f'Failed to verify login code: {exc}',
        ) from exc


@router.post('/resend-verification')
async def resend_verification(payload: ResendVerificationRequest):
    try:
        supabase = get_supabase_client()
        sent = _resend_signup_verification(supabase, payload.email.lower().strip())
        if not sent:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail='Failed to resend verification code.',
            )
        return {'message': 'Verification code sent.'}
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f'Failed to resend verification code: {exc}',
        ) from exc


@router.post('/verify-otp')
async def verify_otp(payload: VerifyOtpRequest):
    try:
        supabase = get_supabase_client()
        result = supabase.auth.verify_otp(
            {
                'type': 'signup',
                'email': payload.email.lower().strip(),
                'token': payload.code.strip(),
            }
        )
        user = getattr(result, 'user', None)
        session = getattr(result, 'session', None)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail='Invalid OTP code.',
            )
        return {
            'message': 'OTP verified successfully.',
            'user_id': str(getattr(user, 'id', '')),
            'email': str(getattr(user, 'email', payload.email)),
            'access_token': getattr(session, 'access_token', None) if session else None,
            'refresh_token': getattr(session, 'refresh_token', None) if session else None,
        }
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f'Failed to verify OTP: {exc}',
        ) from exc


@router.post('/forgot-password')
async def forgot_password(payload: ForgotPasswordRequest):
    try:
        supabase = get_supabase_client()
        supabase.auth.reset_password_for_email(
            payload.email.lower().strip(),
            {
                'redirect_to': 'io.supabase.flutter://login-callback/',
            },
        )
        return {'message': 'Password reset email sent.'}
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f'Failed to send password reset email: {exc}',
        ) from exc


@router.post('/reset-password')
async def reset_password(payload: ResetPasswordRequest):
    try:
        import os
        from supabase import create_client
        temp_client = create_client(
            os.environ['SUPABASE_URL'],
            os.environ['SUPABASE_SERVICE_ROLE_KEY'],
        )
        temp_client.auth.set_session(
            payload.access_token.strip(),
            payload.refresh_token.strip(),
        )
        temp_client.auth.update_user({'password': payload.new_password})
        return {'message': 'Password updated successfully.'}
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f'Failed to reset password: {exc}',
        ) from exc
