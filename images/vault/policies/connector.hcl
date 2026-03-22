# Transit: allow encrypt only (no decrypt)
path "transit/encrypt/connector-db" {
  capabilities = ["update"]
}

# Project ciphertext store (WRITE only; API enforces writing in the correct path)
path "connector/data/projects/+/db" {
  capabilities = ["create", "update", "patch"]
}