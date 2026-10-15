def parse_claims(text):
    claims = []
    pos = 0
    while pos < len(text):
        start = pos
        # ... your logic here ...
        raw = text[start:pos]
        clean = raw.strip()
        claims.append({
            "id": f"c-{len(claims) + 1:03d}",
            "text": clean,
            "source_span": (start, start + len(raw)),
        })
        pos = start + len(raw)
    return claims

# test
result = parse_claims("your sample text here")
print(result)
