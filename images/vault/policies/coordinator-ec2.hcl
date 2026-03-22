# Read project ciphertext (narrowed to only the db leaf)
path "connector/data/projects/+/db" {
  capabilities = ["read"]
}

# Transit: decrypt only
path "transit/decrypt/connector-db" {
  capabilities = ["update"]
}