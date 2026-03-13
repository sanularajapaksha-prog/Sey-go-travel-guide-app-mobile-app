# API Examples

All requests assume `BASE=http://localhost:8000`. Replace with deployed host and add `Authorization: Bearer <token>` where needed.

## Auth
### Register
```bash
curl -X POST \"$BASE/auth/register\" \\
  -H \"Content-Type: application/json\" \\
  -d '{\"full_name\":\"Ada Lovelace\",\"email\":\"ada@example.com\",\"password\":\"Passw0rd!\"}'
```

### Login
```bash
curl -X POST \"$BASE/auth/login\" \\
  -H \"Content-Type: application/json\" \\
  -d '{\"email\":\"ada@example.com\",\"password\":\"Passw0rd!\"}'
```

### Resend verification
```bash
curl -X POST \"$BASE/auth/resend-verification\" \\
  -H \"Content-Type: application/json\" \\
  -d '{\"email\":\"ada@example.com\"}'
```

### Verify OTP
```bash
curl -X POST \"$BASE/auth/verify-otp\" \\
  -H \"Content-Type: application/json\" \\
  -d '{\"email\":\"ada@example.com\",\"code\":\"123456\"}'
```

## Places
### List places
```bash
curl \"$BASE/places?limit=20&offset=0\" -H \"Authorization: Bearer $TOKEN\"
```

### Search places (DB)
```bash
curl \"$BASE/places/search?q=surf&radius_km=80&latitude=6.9271&longitude=79.8612\" \\
  -H \"Authorization: Bearer $TOKEN\"
```

### Recommend places
```bash
curl -X POST \"$BASE/places/recommend\" \\
  -H \"Authorization: Bearer $TOKEN\" \\
  -H \"Content-Type: application/json\" \\
  -d '{\"current_place_id\":\"123\",\"liked_tags\":[\"beach\",\"surf\"],\"disliked_tags\":[\"crowded\"]}'
```

### Google search proxy
```bash
curl -X POST \"$BASE/places/google/search\" \\
  -H \"Content-Type: application/json\" \\
  -d '{\"query\":\"Sigiriya\",\"language\":\"en\"}'
```

### Google details
```bash
curl \"$BASE/places/google/details/ChIJo2LvzQDe4joRfXQtpOfgUaw\"
```

### Place photo
```bash
curl \"$BASE/places/photo/123\" --output place.jpg
```

## Destinations
### Save destination
```bash
curl -X POST \"$BASE/destinations/save\" \\
  -H \"Authorization: Bearer $TOKEN\" \\
  -H \"Content-Type: application/json\" \\
  -d '{\"place_id\":\"123\",\"name\":\"Galle Fort\",\"latitude\":6.026,\"longitude\":80.217,\"tags\":[\"heritage\"],\"description\":\"Old fort\"}'
```

### List my destinations
```bash
curl \"$BASE/destinations/me?limit=20&offset=0\" -H \"Authorization: Bearer $TOKEN\"
```

### Delete destination
```bash
curl -X DELETE \"$BASE/destinations/123\" -H \"Authorization: Bearer $TOKEN\"
```

## Route optimization (planned)
```bash
curl -X POST \"$BASE/route/optimize\" \\
  -H \"Authorization: Bearer $TOKEN\" \\
  -H \"Content-Type: application/json\" \\
  -d '{
    \"origin\": {\"latitude\":6.9271,\"longitude\":79.8612},
    \"destinations\": [
      {\"name\":\"Galle Fort\",\"latitude\":6.026,\"longitude\":80.217},
      {\"name\":\"Ella Rock\",\"latitude\":6.866,\"longitude\":81.046}
    ]
  }'
```

## Sample responses
### /places/search
```json
{
  \"places\": [
    {
      \"id\": \"123\",
      \"name\": \"Arugam Bay\",
      \"primary_category\": \"beach\",
      \"tags\": [\"surf\",\"beach\"],
      \"latitude\": 6.838,
      \"longitude\": 81.838,
      \"avg_rating\": 4.7,
      \"photo_url\": \"https://storage.supabase.co/.../arugam.jpg\"
    }
  ]
}
```

### /auth/login
```json
{
  \"access_token\": \"eyJhbGciOi...\",
  \"refresh_token\": \"eyJhbGciOi...\",
  \"user\": {\"id\": \"abcd-1234\", \"email\": \"ada@example.com\"}
}
```

