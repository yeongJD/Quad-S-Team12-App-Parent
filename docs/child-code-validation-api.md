# Child Code Validation API Contract

This document defines the backend API expected by the parent Flutter app when a parent links a child account.

## Current Frontend Behavior

- During local testing, the app accepts the child code `GDG12-CHILD`.
- In server validation mode, the app sends the entered child code to a backend endpoint.
- Server validation is enabled by launching Flutter with:

```sh
flutter run --dart-define=CHILD_CODE_VALIDATION_URL=https://api.example.com/parent/children/validate-code
```

If `CHILD_CODE_VALIDATION_URL` is omitted, the app falls back to the local testing code.

## Endpoint

`POST /parent/children/validate-code`

The exact host/path can change. The frontend only needs the full URL via `CHILD_CODE_VALIDATION_URL`.

## Request

Headers:

```http
Content-Type: application/json
```

Body:

```json
{
  "code": "GDG12-CHILD"
}
```

## Success Response

Use HTTP `200 OK`.

For a valid child code:

```json
{
  "valid": true
}
```

For an invalid or expired child code:

```json
{
  "valid": false
}
```

## Frontend Interpretation

- `200` with `{ "valid": true }`: child link is accepted and saved locally.
- `200` with `{ "valid": false }`: show "유효하지 않은 자녀코드입니다".
- Non-`200`, malformed JSON, timeout, or network error: treated as validation failure for now.

## Future Extension

The backend may later return child metadata. The current frontend ignores extra fields, so this is backward compatible:

```json
{
  "valid": true,
  "child": {
    "id": "child_123",
    "name": "박진아",
    "birthYear": 2014
  }
}
```

When child metadata becomes available, the frontend can replace locally entered child info with server-confirmed child data.
