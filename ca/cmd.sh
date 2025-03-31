openssl req -x509 -nodes -days 365 -newkey rsa:2048 \                                                       ☁️  󱃾 nimbus 
  -keyout zues.key -out zues.crt \
  -subj "/CN=zues.com" \
  -addext "subjectAltName = DNS:zues.com"

# openssl x509 -in zues.crt -noout -serial 
