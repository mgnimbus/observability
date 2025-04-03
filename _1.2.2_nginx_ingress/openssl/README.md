# Using OpenSSL (Self-Signed)

This involves creating your own mini Certificate Authority (CA) and using it to sign a server certificate for Nginx.

## Generate CA Key and Certificate:
```bash
# Generate CA private key
openssl genpkey -algorithm RSA -out ca.key -aes256 
# Use a strong passphrase! gowthammeda

# Generate CA certificate (valid for, e.g., 5 years)
openssl req -x509 -new -nodes -key ca.key -sha256 -days 1825 -out ca.crt \
  -subj "/C=US/ST=TX/L=KT/O=ObsrvgInternal/CN=MyObsrvCA"
# Keep ca.key very secure! ca.crt is the public part to distribute.
```
## Generate Server Key and Certificate Signing Request (CSR):

### Generate Server private key
```bash
openssl genpkey -algorithm RSA -out server.key
```
### Create CSR

```bash
openssl req -new -key server.key -out server.csr \
  -subj "/C=US/ST=TX/L=KT/O=obsrv/CN=*.gowthamvandana.com" 
  # Use your intended hostname!
```
```
# You can also add Subject Alternative Names (SANs) if needed, which is recommended:
# Create a config file (e.g., san.cnf):
# [ req ]
# distinguished_name = req_distinguished_name
# req_extensions = v3_req
# prompt = no
# [ req_distinguished_name ]
# C = IN
# ST = Telangana
# L = Hyderabad
# O = MyOrgInternal
# CN = ingest.your-internal-domain.com
# [ v3_req ]
# keyUsage = keyEncipherment, dataEncipherment
# extendedKeyUsage = serverAuth
# subjectAltName = @alt_names
# [ alt_names ]
# DNS.1 = ingest.your-internal-domain.com
# DNS.2 = *.your-internal-domain.com # Optional wildcard
# DNS.3 = <nlb-dns-name>             # Optional NLB DNS name
# openssl req -new -key server.key -out server.csr -config san.cnf
```

## Sign the Server CSR with your CA:

```bash

openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 365 -sha256

# or   

# Use san.cnf if you created it
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
-out server.crt -days 365 -sha256 -extfile san.cnf -extensions v3_req

# Enter CA key passphrase when prompted.
# server.crt is your signed server certificate.
```  

## Create Kubernetes TLS Secret: You now have server.crt, server.key, and ca.crt. Nginx needs server.crt and server.key. The OpenTelemetry collector will need ca.crt to trust the server certificate. 

### Create the TLS secret for Nginx:

kubectl create secret tls nginx-ingress-tls \
  --cert=server.crt \
  --key=server.key \
  --namespace <your-nginx-namespace> # e.g., ingress-nginx

Create Kubernetes Secret/ConfigMap for CA Cert: Make the CA cert available to your OpenTelemetry Collector pods. A ConfigMap is often sufficient:
Bash

kubectl create configmap otel-collector-ca \
  --from-file=ca.crt=ca.crt \
  --namespace <your-otel-collector-namespace> # e.g., observability


```
openssl verify -verbose -CAfile ca.crt server.crt

```