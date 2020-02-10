# Generate key pair
openssl genrsa -out keypair.pem 2048
# Extract public key
openssl rsa -in keypair.pem -pubout -out pubkey.pem
