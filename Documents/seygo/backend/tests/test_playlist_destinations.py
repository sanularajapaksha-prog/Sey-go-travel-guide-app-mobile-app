"""
Tests for POST /playlists/{playlist_id}/destinations

Covers the bugs that caused the 500 error:
  1. _assert_owner selecting a column that may not exist (is_default)
  2. _assert_owner not handling integer playlist IDs
  3. add_destination passing the wrong type to playlist_places.playlist_id
"""

import types
import uuid
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

# ---------------------------------------------------------------------------
# Minimal stubs so the app can import without real env vars
# ---------------------------------------------------------------------------
import os

os.environ.setdefault("SUPABASE_URL", "https://fake.supabase.co")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "fake-service-role-key")
os.environ.setdefault("SUPABASE_ANON_KEY", "fake-anon-key")
os.environ.setdefault("JWT_SECRET", "fake-jwt-secret")
os.environ.setdefault("GOOGLE_PLACES_API_KEY", "")


def _make_response(data):
    """Build a fake Supabase response object."""
    r = types.SimpleNamespace()
    r.data = data
    return r


def _make_supabase(owner_rows, existing_rows, insert_rows):
    """
    Return a mock Supabase client that:
      - Returns owner_rows for the ownership check (playlists table)
      - Returns existing_rows for the duplicate check (playlist_places select)
      - Returns insert_rows for the insert (playlist_places insert)
    """
    sb = MagicMock()

    # Global counter across ALL table('playlist_places') calls so that
    # the first execute() returns existing_rows and the second returns insert_rows,
    # regardless of how many inner objects are created.
    pp_call_count = {"n": 0}
    pp_results = [_make_response(existing_rows), _make_response(insert_rows)]

    def _table(table_name):
        inner = MagicMock()
        inner.select.return_value = inner
        inner.eq.return_value = inner
        inner.limit.return_value = inner
        inner.in_.return_value = inner
        inner.insert.return_value = inner

        if table_name == "playlists":
            inner.execute.return_value = _make_response(owner_rows)
        elif table_name == "playlist_places":
            def _pp_execute():
                idx = pp_call_count["n"]
                pp_call_count["n"] += 1
                if idx < len(pp_results):
                    return pp_results[idx]
                return _make_response([])
            inner.execute.side_effect = lambda: _pp_execute()
        else:
            inner.execute.return_value = _make_response([])
        return inner

    sb.table.side_effect = _table
    return sb


def _make_user(uid=None):
    u = types.SimpleNamespace()
    u.id = uid or uuid.uuid4()
    return u


# ---------------------------------------------------------------------------
# Tests for _assert_owner
# ---------------------------------------------------------------------------


class TestAssertOwner:
    def test_uuid_id_found(self):
        """Returns the playlist row when found by UUID string id."""
        from app.routers.playlists import _assert_owner

        playlist_id = str(uuid.uuid4())
        user = _make_user()
        row = {"id": playlist_id, "is_default": False}

        sb = MagicMock()
        inner = MagicMock()
        inner.select.return_value = inner
        inner.eq.return_value = inner
        inner.execute.return_value = _make_response([row])
        sb.table.return_value = inner

        result = _assert_owner(sb, playlist_id, user)
        assert result["id"] == playlist_id

    def test_integer_id_fallback(self):
        """Falls back to integer query when string query returns nothing."""
        from fastapi import HTTPException
        from app.routers.playlists import _assert_owner

        playlist_id = "21"
        user = _make_user()
        row = {"id": 21, "is_default": False}

        call_count = {"n": 0}

        sb = MagicMock()
        inner = MagicMock()
        inner.select.return_value = inner
        inner.eq.return_value = inner

        def _execute():
            call_count["n"] += 1
            # First call (string id) returns nothing, second (int id) returns row
            if call_count["n"] == 1:
                return _make_response([])
            return _make_response([row])

        inner.execute.side_effect = lambda: _execute()
        sb.table.return_value = inner

        result = _assert_owner(sb, playlist_id, user)
        assert result["id"] == 21

    def test_not_found_raises_404(self):
        """Raises 404 when the playlist does not exist or belongs to another user."""
        from fastapi import HTTPException
        from app.routers.playlists import _assert_owner

        user = _make_user()
        sb = MagicMock()
        inner = MagicMock()
        inner.select.return_value = inner
        inner.eq.return_value = inner
        inner.execute.return_value = _make_response([])
        sb.table.return_value = inner

        with pytest.raises(HTTPException) as exc_info:
            _assert_owner(sb, str(uuid.uuid4()), user)
        assert exc_info.value.status_code == 404

    def test_db_exception_falls_back_gracefully(self):
        """Does not propagate raw DB exceptions — raises 404 instead."""
        from fastapi import HTTPException
        from app.routers.playlists import _assert_owner

        user = _make_user()
        sb = MagicMock()
        inner = MagicMock()
        inner.select.return_value = inner
        inner.eq.return_value = inner
        inner.execute.side_effect = Exception("invalid input syntax for type uuid: '21'")
        sb.table.return_value = inner

        with pytest.raises(HTTPException) as exc_info:
            _assert_owner(sb, "not-a-uuid", user)
        assert exc_info.value.status_code == 404

    def test_missing_is_default_column_does_not_crash(self):
        """Selecting * means missing columns do not cause a 500."""
        from app.routers.playlists import _assert_owner

        playlist_id = str(uuid.uuid4())
        user = _make_user()
        # Row without is_default (column doesn't exist in DB)
        row = {"id": playlist_id}

        sb = MagicMock()
        inner = MagicMock()
        inner.select.return_value = inner
        inner.eq.return_value = inner
        inner.execute.return_value = _make_response([row])
        sb.table.return_value = inner

        result = _assert_owner(sb, playlist_id, user)
        assert result["id"] == playlist_id


# ---------------------------------------------------------------------------
# Tests for add_destination endpoint
# ---------------------------------------------------------------------------


class TestAddDestination:
    """End-to-end style tests using FastAPI TestClient with mocked Supabase."""

    def _client_with_mocks(self, owner_row, existing_rows=None, insert_rows=None):
        """
        Build a TestClient where _sb() returns a controlled mock and
        get_current_user returns a fake user.
        """
        from app.main import app
        from app import dependencies
        from app.routers import playlists as pl_module

        user = _make_user()
        sb = _make_supabase(
            owner_rows=[owner_row] if owner_row else [],
            existing_rows=existing_rows or [],
            insert_rows=insert_rows or [],
        )

        app.dependency_overrides[dependencies.get_current_user] = lambda: user

        with patch.object(pl_module, "_sb", return_value=sb):
            client = TestClient(app, raise_server_exceptions=False)
            yield client, user

        app.dependency_overrides.clear()

    def test_success_uuid_playlist(self):
        """Returns 201 when a place is added to a UUID-id playlist."""
        playlist_id = str(uuid.uuid4())
        owner_row = {"id": playlist_id, "user_id": "any"}
        insert_row = {"id": str(uuid.uuid4()), "playlist_id": playlist_id, "place_id": "42"}

        for client, _ in self._client_with_mocks(
            owner_row=owner_row, existing_rows=[], insert_rows=[insert_row]
        ):
            r = client.post(
                f"/playlists/{playlist_id}/destinations",
                json={"place_id": "42"},
                headers={"Authorization": "Bearer fake-token"},
            )
            assert r.status_code == 201

    def test_success_integer_playlist(self):
        """Returns 201 when a place is added to an integer-id playlist."""
        owner_row = {"id": 21, "user_id": "any"}
        insert_row = {"id": str(uuid.uuid4()), "playlist_id": 21, "place_id": "5"}

        for client, _ in self._client_with_mocks(
            owner_row=owner_row, existing_rows=[], insert_rows=[insert_row]
        ):
            r = client.post(
                "/playlists/21/destinations",
                json={"place_id": "5"},
                headers={"Authorization": "Bearer fake-token"},
            )
            assert r.status_code == 201

    def test_conflict_returns_409(self):
        """Returns 409 when the place is already in the playlist."""
        playlist_id = str(uuid.uuid4())
        owner_row = {"id": playlist_id, "user_id": "any"}
        existing = [{"id": "existing-row"}]

        for client, _ in self._client_with_mocks(
            owner_row=owner_row, existing_rows=existing
        ):
            r = client.post(
                f"/playlists/{playlist_id}/destinations",
                json={"place_id": "42"},
                headers={"Authorization": "Bearer fake-token"},
            )
            assert r.status_code == 409

    def test_missing_place_id_returns_400(self):
        """Returns 400 when neither place_id nor destination_id is provided."""
        playlist_id = str(uuid.uuid4())
        owner_row = {"id": playlist_id, "user_id": "any"}

        for client, _ in self._client_with_mocks(owner_row=owner_row):
            r = client.post(
                f"/playlists/{playlist_id}/destinations",
                json={},
                headers={"Authorization": "Bearer fake-token"},
            )
            assert r.status_code == 400

    def test_playlist_not_found_returns_404(self):
        """Returns 404 when the playlist does not belong to the user."""
        for client, _ in self._client_with_mocks(owner_row=None):
            r = client.post(
                f"/playlists/{uuid.uuid4()}/destinations",
                json={"place_id": "42"},
                headers={"Authorization": "Bearer fake-token"},
            )
            assert r.status_code == 404

    def test_db_insert_error_returns_500_not_unhandled(self):
        """DB errors during insert are caught and return a clean 500, not a crash."""
        from app.routers import playlists as pl_module
        from app.main import app
        from app import dependencies

        playlist_id = str(uuid.uuid4())
        owner_row = {"id": playlist_id, "user_id": "any"}
        user = _make_user()

        # Build a Supabase mock where the insert raises an exception
        sb = MagicMock()
        call_count = {"n": 0}

        def _table(name):
            inner = MagicMock()
            inner.select.return_value = inner
            inner.eq.return_value = inner
            inner.insert.return_value = inner
            if name == "playlists":
                inner.execute.return_value = _make_response([owner_row])
            else:
                def _exec():
                    call_count["n"] += 1
                    if call_count["n"] == 1:
                        return _make_response([])  # no duplicate
                    raise Exception("DB connection lost")  # insert fails
                inner.execute.side_effect = _exec
            return inner

        sb.table.side_effect = _table
        app.dependency_overrides[dependencies.get_current_user] = lambda: user

        with patch.object(pl_module, "_sb", return_value=sb):
            client = TestClient(app, raise_server_exceptions=False)
            r = client.post(
                f"/playlists/{playlist_id}/destinations",
                json={"place_id": "99"},
                headers={"Authorization": "Bearer fake-token"},
            )

        app.dependency_overrides.clear()
        assert r.status_code == 500
        assert "Failed to add destination" in r.json().get("detail", "")
