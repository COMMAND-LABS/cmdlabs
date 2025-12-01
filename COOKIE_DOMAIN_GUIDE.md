# Cookie Domain Configuration Guide for Docker Compose

## The Problem

When running services in Docker Compose, cookies face a fundamental challenge:

1. **Cookies are origin-specific**: A cookie set by `http://127.0.0.1:4000` can only be read by `http://127.0.0.1:4000`
2. **IP addresses can't be cookie domains**: Browsers reject cookies with IP addresses (like `127.0.0.1`) as domains
3. **Different ports = different origins**: `127.0.0.1:3000` and `127.0.0.1:4000` are different origins

## Current Setup

- **UI**: `http://127.0.0.1:3000` (browser)
- **API**: `http://127.0.0.1:4000` (container)
- **Browser makes requests**: From `127.0.0.1:3000` → `127.0.0.1:4000`

## Solution Options

### Option 1: No Domain (Recommended for Local Development) ✅

**Configuration:**
```yaml
environment:
  - COOKIE_DOMAIN=
  - ENVIRONMENT=development
```

**How it works:**
- Cookie is set without a domain attribute
- Cookie is origin-specific to `127.0.0.1:4000`
- Browser sends cookie with requests to `127.0.0.1:4000` (because of `credentials: "include"` in fetch)
- Cookie is readable by the API when browser makes requests

**Pros:**
- Simple, works for local development
- No domain conflicts

**Cons:**
- Cookie only works for the exact origin that set it
- Won't work if you access via `localhost` instead of `127.0.0.1`

### Option 2: Use `localhost` Instead of `127.0.0.1`

**Configuration:**
```yaml
# Access UI via http://localhost:3000
# Access API via http://localhost:4000
environment:
  - COOKIE_DOMAIN=localhost
  - ENVIRONMENT=development
```

**Update docker-compose:**
```yaml
ui:
  environment:
    - NEXT_PUBLIC_AUTH_API_URL=http://localhost:4000
```

**How it works:**
- Use `localhost` instead of `127.0.0.1` in browser
- Set domain to `localhost` (but code will ignore it for development)
- Cookies work because both are on `localhost` domain

**Pros:**
- More intuitive URLs
- Works with domain attribute

**Cons:**
- Still has port origin issue (but cookies are sent with credentials)

### Option 3: Reverse Proxy (Best for Production-like Setup)

Use nginx or Traefik to route both UI and API through the same origin:

```
http://localhost:3000/ui/*  → UI container
http://localhost:3000/api/*  → API container
```

**Pros:**
- Same origin = cookies work seamlessly
- Production-like setup

**Cons:**
- More complex setup
- Requires additional proxy container

### Option 4: Production Setup

**Configuration:**
```yaml
environment:
  - COOKIE_DOMAIN=.kalygo.io
  - ENVIRONMENT=production
```

**How it works:**
- Domain starts with `.` (dot) = works for all subdomains
- `secure=True` and `samesite="None"` for cross-site cookies
- Cookies work across `api.kalygo.io`, `app.kalygo.io`, etc.

## Recommended Configuration

### For Local Development (Docker Compose):

```yaml
ai-api:
  environment:
    - COOKIE_DOMAIN=          # Empty = no domain attribute
    - ENVIRONMENT=development
```

**Why this works:**
1. Cookie is set without domain → origin-specific to `127.0.0.1:4000`
2. Browser makes requests from `127.0.0.1:3000` to `127.0.0.1:4000`
3. With `credentials: "include"` in fetch, browser sends the cookie
4. API receives the cookie because it was set by the same origin (`127.0.0.1:4000`)

### For Production:

```yaml
ai-api:
  environment:
    - COOKIE_DOMAIN=.kalygo.io  # Dot prefix for subdomain sharing
    - ENVIRONMENT=production
```

**Why this works:**
1. Domain `.kalygo.io` allows cookies across subdomains
2. `secure=True` + `samesite="None"` enables cross-site cookies
3. Works with HTTPS

## Current Code Behavior

The auth router already handles this correctly:

```python
# Don't use IP addresses as cookie domains
if cookie_domain and (cookie_domain.startswith("127.") or cookie_domain == "localhost"):
    cookie_domain = None  # Ignore IP/localhost domains

if is_development:
    cookie_kwargs["secure"] = False
    cookie_kwargs["samesite"] = "Lax"
    # Don't set domain for localhost/IP addresses
    if cookie_domain and not cookie_domain.startswith("127.") and cookie_domain != "localhost":
        cookie_kwargs["domain"] = cookie_domain
```

## Testing Cookie Behavior

1. **Check if cookie is set:**
   - Open browser DevTools → Application → Cookies
   - Look for `jwt` cookie
   - Should be under `http://127.0.0.1:4000`

2. **Verify cookie is sent:**
   - Open Network tab
   - Make a request to API
   - Check Request Headers for `Cookie: jwt=...`

3. **Common issues:**
   - Cookie not set → Check API logs for cookie setting
   - Cookie not sent → Ensure `credentials: "include"` in fetch
   - Cookie rejected → Check browser console for cookie warnings

## Summary

**For Docker Compose local development:**
- ✅ Set `COOKIE_DOMAIN=` (empty)
- ✅ Use `127.0.0.1` or `localhost` consistently
- ✅ Ensure `credentials: "include"` in fetch requests
- ✅ Code already handles IP addresses correctly

**For production:**
- ✅ Set `COOKIE_DOMAIN=.yourdomain.com` (with dot prefix)
- ✅ Use HTTPS
- ✅ Code will use `secure=True` and `samesite="None"`

