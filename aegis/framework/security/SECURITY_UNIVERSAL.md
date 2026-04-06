# Security Guidelines — Universal

> **MANDATORY**: Read this entire file before implementing any endpoint, form, upload, or logic involving user data, payments, or mutable state. These rules are not optional. Apply them to ALL project code, regardless of framework or language.
>
> This document is project-agnostic. Adapt the code examples to your stack, but never ignore the principles.

---

## 1. Race Conditions

Test race conditions in **any operation** that involves:

- Balance, credits, or tokens
- Purchase, payment, or financial transaction
- Like, favorite, vote, or any state that toggles
- Content generation or processing (avoid processing the same job twice)
- Status update (order, subscription, ticket, etc.)
- Inventory, seats, tickets, or any limited resource
- Creation of unique resources (username, slug, coupon code)

**How to test**: Fire simultaneous identical requests AND with variations (different IDs, different quantities, parameter combinations). Do this on ALL endpoints that perform writes.

**Implementation principles**:
- Use transactions with an appropriate isolation level (Serializable for financial operations)
- Use optimistic locks (versioning) or pessimistic locks (SELECT FOR UPDATE) depending on the case
- For processing queues, use idempotency keys — if the same job arrives twice, execute only once
- For payment gateway webhooks, always check if the resource has already been processed before acting

```
// Pseudocode — adapt to your ORM/language
transaction(isolationLevel: SERIALIZABLE) {
  resource = findById(id)
  if (resource.status != EXPECTED_STATUS) throw AlreadyProcessedError
  resource.status = NEW_STATUS
  save(resource)
}
```

**Special attention with webhooks**: Gateways (Stripe, Mercado Pago, PayPal, PagSeguro, Asaas, etc.) may send the same webhook multiple times. Use the event ID as an idempotency key and store already-processed events.

---

## 2. IDOR (Insecure Direct Object Reference)

Validate IDOR on **every endpoint that receives an ID** — always check on the backend that the resource belongs to the authenticated user.

```
// ❌ WRONG — any user can access any resource
resource = findById(params.id)

// ✅ CORRECT — verifies ownership
resource = findByIdAndOwner(params.id, authenticatedUser.id)
if (!resource) return 404
```

**Where to apply (no exceptions)**:
- Every endpoint that receives a resource ID in the URL (path param or query param)
- Every endpoint that returns data for a specific resource
- Every endpoint that modifies or deletes a resource
- Private file download endpoints
- Webhook endpoints — validate cryptographic signature, never trust only the payload
- Listings — always filter by owner, never return all records

**Golden rule**: If the endpoint receives an ID, the backend MUST verify that `resource.ownerId === currentUser.id` (or equivalent role). No exceptions.

---

## 3. Input Validation

Limit input size on **all fields, no exceptions**. Use a schema validation library (zod, yup, joi, pydantic, etc.) on every endpoint.

**Principles**:
- Define the schema BEFORE writing the logic — every field has a type, minimum size, maximum size, and expected format
- Reject the entire request if any field fails validation
- Return generic errors to the client, detailed errors only in logs

**Mandatory rules for every field**:

| Field type | Mandatory validations |
|------------|---------------------|
| String (free text) | min, max, trim, sanitize HTML |
| String (enum) | Fixed list of allowed values |
| Email | Email format + max 254 chars |
| URL | https protocol + hostname allowlist |
| Number | min, max, integer vs float |
| Date | Valid format, acceptable range (not future if inappropriate) |
| Boolean | Only true/false, no string coercion |
| Array | maxItems, validate each item individually |
| Object | Validate each property, reject extra properties |

**Additional rules**:
- Sanitize HTML in any field that accepts free text — both on the client (DOMPurify) and on the server (sanitize-html or equivalent)
- Never interpolate user input in: SQL queries (use parameterized queries), AI prompts (avoid prompt injection), email templates (avoid header injection), shell commands (never do this), regular expressions (avoid ReDoS)
- Name/personal text fields: allow only letters (including accents/unicode), spaces, hyphens, and apostrophes
- Limit form submission rate (e.g., 1 submit every 5 seconds per IP)
- JSON payloads: limit total body size (e.g., max 1MB for normal APIs, configure in middleware)
- Query strings: validate and limit — do not accept unexpected parameters

---

## 4. File Uploads

Validate uploads by **MIME type AND magic bytes**, not just extension. Extensions are trivial to forge.

**Validation layers (apply ALL)**:

1. **Size**: Maximum limit per type (e.g., 10MB for images, 50MB for documents). Reject before processing.

2. **Magic bytes**: Read the first bytes of the file to identify the actual type. Use libraries: `file-type` (Node), `python-magic` (Python), `mimetype` (Go).

3. **Extension**: Check as redundancy, never as the sole validation.

4. **Decoding**: Try to process the file as the expected type (e.g., open as image with sharp/Pillow). If it fails, reject — it may be a malicious file in disguise.

5. **Resolution/dimensions** (for images): Limit maximum resolution to prevent pixel flood attacks (e.g., max 8000x8000).

**Storage rules**:
- Never serve uploads directly from your server — use external storage (S3, R2, GCS) with signed URLs and TTL
- Rename the file with a UUID — never use the original name (avoid path traversal)
- Strip EXIF/metadata before storing — photos may contain GPS, device data, personal information
- Process and re-encode the file before storing (e.g., re-compress image with sharp/Pillow) — eliminates hidden payloads
- Scan uploads for viruses on document uploads (if applicable to your use case)
- Set Content-Disposition to `attachment` for downloads, never `inline` for dangerous types

**Never**:
- Store uploads in the same folder as the application code
- Execute or interpret content from uploads
- Trust the Content-Type from the HTTP header (it is set by the client)

---

## 5. URLs and External Resources

Restrict URLs to your domain and **do not accept arbitrary URLs from the client**.

```
// Pseudocode
function isValidResourceUrl(url):
  parsed = parseUrl(url)
  if parsed.hostname NOT IN allowedHosts: return false
  if parsed.protocol != "https": return false
  if parsed.search contains suspicious params: return false
  return true
```

**Never**:
- Accept arbitrary URLs from the client to render images or embed content (SSRF)
- Perform server-side fetch of user-provided URLs without rigorous validation
- Use query strings to pass internal file paths
- Redirect to user-provided URLs without validating against an allowlist (Open Redirect)
- Trust callback/webhook URLs without validating the signature

**If you MUST fetch an external URL** (e.g., link metadata):
- Domain allowlist
- Short timeout (max 5s)
- Limit response size
- Do not follow redirects to domains outside the allowlist
- Block private/internal IPs (127.0.0.1, 10.x.x.x, 192.168.x.x, etc.) — prevents SSRF

---

## 6. Business Logic and Timing

Review all logic involving **time windows** to prevent timing exploitation.

**Payments and financial transactions**:
- Gateway confirmation → only then execute the action (deliver product, activate subscription, etc.)
- Never trust the client to report that payment was made
- Validate paid amount vs. expected amount on the server (prevent price manipulation)
- Links/access tokens to paid resources must have a TTL
- Signed URLs with expiration for paid content downloads

**Refund / Cancellation**:
- Define a clear window and validate on the backend
- Check conditions before approving (downloads made, service usage, etc.)
- Revoke access immediately after refund

**Vouchers, invitations, and codes**:
- Generate with sufficient entropy (UUID v4 or higher, never sequential)
- Define TTL and maximum number of redemptions
- Validate that it has not been redeemed before processing
- Rate limit for redemption attempts (prevent brute force)

**Promotions and coupons**:
- Validate on the backend — never trust the client
- Usage limit per coupon AND per user
- Verify validity on the server (do not trust the client timezone)
- Log usage for auditing

**Subscriptions and trials**:
- Verify subscription status on the server on every protected request
- Do not trust local flags/cookies to determine access
- Handle cancellation webhook immediately

---

## 7. Authentication and Session

**Fundamental rules**:
- Never implement authentication from scratch — use established libraries (NextAuth, Auth.js, Passport, Django Auth, etc.)
- JWT tokens: short TTL (15min–1h), refresh tokens with rotation
- Sessions: store server-side (Redis/DB), cookie httpOnly + secure + sameSite
- Rate limit on login: max 5 attempts in 15 minutes per IP/email
- Lockout after excessive attempts (temporary, with reset via email)
- Never return different messages for "email does not exist" vs. "wrong password" (prevent user enumeration)
- Logout must invalidate the session server-side, not just delete the cookie
- Force re-authentication for sensitive actions (change email, change password, delete account)
- Implement CSRF protection on all forms that change state

**API Keys (if applicable)**:
- Store only the hash, never the plain text value
- Allow multiple keys per user with descriptive names
- Allow individual revocation
- Log usage for auditing

---

## 8. Honeypots and Defense in Depth

Implement honeypots as an additional low-cost defense:

**Form honeypot**:
- Add a hidden field in the form (e.g., `name="website"` or `name="company_url"`)
- The field is invisible to humans (CSS: `position: absolute; left: -9999px`)
- Bots fill in all fields — if this field comes filled in, it is a bot
- Return 200 with a fake response (do not alert the bot that it was detected)

**Decoy endpoints**:
- Create routes that look sensitive but return fictitious data and log the access:
  - `/api/admin/users`, `/api/v2/export`, `/api/internal/config`
  - `/wp-admin/`, `/phpmyadmin/`, `/.env`, `/xmlrpc.php`
- Every access to these endpoints → monitoring alert + temporary IP block
- Implementation cost: near zero. Cost to the attacker: wasted time.

**Defense in depth (general principle)**:
- Never rely on a single layer of protection
- Validate on the client AND on the server
- Rate limit at the edge AND in the application
- Authenticate AND verify authorization at each layer

---

## 9. Security Headers

Configure the following headers on ALL HTTP responses. Adapt to your framework:

| Header | Value | What it prevents |
|--------|-------|-----------------|
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` | Downgrade to HTTP |
| `X-Frame-Options` | `SAMEORIGIN` | Clickjacking |
| `X-Content-Type-Options` | `nosniff` | MIME sniffing |
| `Referrer-Policy` | `origin-when-cross-origin` | Sensitive URL leaks |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` | Unauthorized hardware access |
| `X-DNS-Prefetch-Control` | `on` | Performance (not security) |

**Content-Security-Policy (CSP)**:
- Start restrictive: `default-src 'self'`
- Add exceptions as needed for third-party scripts/images (analytics, CDN, payment gateway, ads)
- Never use `unsafe-inline` for scripts in production if possible — use nonces
- If you need `unsafe-inline` (e.g., for styled-components), document the reason
- Test CSP in report-only mode before activating

**CORS**:
- Never use `Access-Control-Allow-Origin: *` on authenticated APIs
- Explicitly define the allowed domains
- Be careful with credentials: `Access-Control-Allow-Credentials: true` requires an explicit origin

---

## 10. Rate Limiting

Apply rate limiting on **all public endpoints**. Adapt the limits to your use case.

**Reference limits by endpoint type**:

| Endpoint type | Suggested limit | Window |
|---------------|----------------|--------|
| Login / Registration | 5–10 requests | 15 minutes |
| File upload | 5 requests | 1 minute |
| Processing / Generation | 3–5 requests | 1 minute |
| Checkout / Payment | 10 requests | 1 minute |
| Read APIs (authenticated) | 60 requests | 1 minute |
| Read APIs (public) | 30 requests | 1 minute |
| Webhooks | 30 requests | 1 minute |
| Public pages | 120 requests | 1 minute |
| Password reset | 3 requests | 15 minutes |

**Implementation**:
- Use Redis/Upstash for distributed rate limiting
- Identify by IP + userId (if authenticated)
- Return `429 Too Many Requests` with `Retry-After` header
- Consider progressive rate limiting: first request fast, then increasing delay
- For high-traffic public APIs, consider rate limiting at the edge (Cloudflare, Vercel Edge, etc.)

---

## 11. Sensitive Data and Privacy

### Never store:
- Credit card data (delegate to the payment gateway)
- Passwords in plain text (use bcrypt/argon2 with salt)
- API tokens in plain text in the database (store only the hash)
- Temporary processing data after completion (e.g., photos used to generate artwork)

### Store with care:
- Email: necessary for communication → encrypt at rest if possible
- Personal data: minimum necessary for the service to function (minimization principle)
- Logs: never log passwords, tokens, card data, sensitive personal data

### Privacy and compliance (LGPD / GDPR):
- Clear and accessible privacy policy on the site
- Option to delete data at any time (right to be forgotten)
- Explicit consent for marketing emails (unchecked checkbox)
- Documented legal basis for each type of data collected
- Notify users in case of a breach
- Export personal data in a readable format (right to portability)
- Distinguish between data necessary for the service vs. marketing data

### Secrets and environment variables:
- Never commit secrets to the repository (use .env + .gitignore) — see [Section 16](#16-environment-files-and-secrets-in-version-control) for detailed rules
- Rotate secrets periodically
- Use secret managers in production (Vault, AWS Secrets Manager, Vercel env, etc.)
- Different secrets for dev/staging/production

---

## 12. Logging and Monitoring

**What to log (always)**:
- Authentication attempts (success and failure)
- Access to protected resources
- Validation errors (invalid input may indicate an attack)
- Honeypot access
- Rate limit hits
- Payment errors
- Changes to sensitive data (email, password, permissions)

**What to NEVER log**:
- Passwords (not even in case of error)
- Session tokens / JWT / API keys
- Credit card data
- Complete personal data (log only IDs/hashes)

**Format**:
- Structured logging (JSON) with: timestamp, level, message, userId, requestId, IP, userAgent
- Include requestId to correlate logs from the same request
- Automatic alerts for: spikes in 4xx/5xx errors, honeypot access, excessive rate limiting, repeated login attempts

---

## 13. Dependencies and Supply Chain

- Keep dependencies up to date — run `npm audit` / `pip audit` / equivalent regularly
- Use a lockfile (package-lock.json, poetry.lock, etc.) and commit it to the repository
- Review changelogs before updating major dependencies
- Prefer dependencies with active maintenance and many downloads/stars
- Consider using Dependabot / Renovate for automatic updates
- Never install packages from untrusted sources
- For critical packages (auth, crypto, payment), prefer the provider's official libraries

---

## 14. Security Checklist per Feature

Before considering **any feature** ready for production, verify:

### Input and data
- [ ] All inputs validated with schema validation (types, sizes, formats)
- [ ] HTML sanitized in free text fields
- [ ] No interpolation of user input in queries/prompts/templates/commands
- [ ] Payload size limited

### Authorization
- [ ] IDOR verified — resource belongs to the authenticated user
- [ ] Permissions/roles verified on the backend (do not trust the client)
- [ ] Sensitive actions require re-authentication

### Protection
- [ ] Rate limiting applied on the endpoint
- [ ] CSRF protection on forms that change state
- [ ] Transaction with lock for concurrent write operations

### Data
- [ ] No sensitive data in the response that should not be there
- [ ] No console.log/print with user data in production
- [ ] Generic error for the client, detailed error only in logs
- [ ] Temporary data cleaned up after processing

### Upload (if applicable)
- [ ] Validated by magic bytes + extension + decoding
- [ ] Size limited
- [ ] File renamed with UUID
- [ ] EXIF/metadata removed
- [ ] Stored in external storage with signed URL

### URLs and external resources (if applicable)
- [ ] URLs validated against domain allowlist
- [ ] No SSRF — no fetching arbitrary URLs server-side
- [ ] Redirects validated against allowlist

### Infrastructure
- [ ] Security headers present
- [ ] CORS configured restrictively
- [ ] Secrets in environment variables (not hardcoded)
- [ ] Adequate logging without sensitive data

---

## 15. Quick Reference: Top 10 Most Common Mistakes

| # | Mistake | Consequence | Prevention |
|---|---------|-------------|------------|
| 1 | Not validating input size | DoS, buffer overflow, storage costs | Schema validation on everything |
| 2 | Trusting the client for authorization | Unauthorized access to others' data | IDOR check on the backend always |
| 3 | Validating upload only by extension | Disguised malware upload | Magic bytes + decoding |
| 4 | Fetching user-provided URL | SSRF, internal network access | Allowlist + private IP blocking |
| 5 | Webhook without signature verification | Fraudulent actions | Always validate HMAC/signature |
| 6 | No rate limit on login | Password brute force | 5 attempts / 15 min |
| 7 | No transaction on financial operation | Race condition, duplication | Serializable + idempotency key |
| 8 | Logging sensitive data | Password/token leak via logs | Never log credentials |
| 9 | Secrets in the repository | Total compromise | .env + secret manager |
| 10 | Absent or permissive CSP | XSS, data exfiltration | Restrictive CSP from day 1 |

---

## 16. Environment Files and Secrets in Version Control

NEVER commit .env files, .env.local, .env.production, or any file containing secrets to the repository.

**Required .gitignore entries:**

```
.env
.env.*
*.pem
*.key
credentials.json
```

**Pre-commit check (mandatory):**

Before every commit, verify no secrets are staged:

```
git diff --cached --name-only | grep -E '\.env|credentials|\.pem|\.key'
```

If any match, unstage immediately. No exceptions.

**Build command enforcement:**

The `/aegis:build` stop hook rejects TASK_COMPLETE if any staged file matches the secrets pattern. This is a hard block.

**Additional rules:**
- Never hardcode API keys, database URLs, or auth tokens in source code
- Use environment variables or secret managers (Vault, AWS Secrets Manager, Vercel env)
- Different secrets for dev/staging/production environments
- Rotate secrets periodically
- If a secret is accidentally committed, rotate it immediately — removing from git history is not enough
