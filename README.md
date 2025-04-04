## First check AWS Records are created ot not

```
ping otel.gowthamvandana.com

nslookup otel.gowthamvandana.com


dig otel.gowthamvandana.com

```


```
# Test HTTP connection (usually port 80)
curl -v http://otel.gowthamvandana.com

# Test HTTPS connection (usually port 443)
curl -v https://otel.gowthamvandana.com
# or specifically test the port
curl -v https://otel.gowthamvandana.com:443

```

## Debugging Route53 
```bash
 aws route53 list-hosted-zones-by-name --dns-name gowthamvandana.com

# /hostedzone/Z04338881KRW1EL6YAQ5P

aws route53 list-resource-record-sets --hosted-zone-id /hostedzone/Z04338881KRW1EL6YAQ5P

aws route53 get-hosted-zone --id Z04338881KRW1EL6YAQ5P

# check whether its connected to right VPC


```
# Test HTTP connection (usually port 80)
curl -v http://otel.gowthamvandana.com

# Test HTTPS connection (usually port 443)
curl -v https://otel.gowthamvandana.com
# or specifically test the port
curl -v https://otel.gowthamvandana.com:443

```
/ # # Test HTTP connection (usually port 80)
/ # curl -v http://otel.gowthamvandana.com
 -v https://otel.gowthamvandana.com:443*   Trying 10.0.23.104:80...
* Connected to otel.gowthamvandana.com (10.0.23.104) port 80 (#0)
> GET / HTTP/1.1
> Host: otel.gowthamvandana.com
> User-Agent: curl/7.79.1
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 308 Permanent Redirect
< Date: Fri, 04 Apr 2025 16:29:16 GMT
< Content-Type: text/html
< Content-Length: 164
< Connection: keep-alive
< Location: https://otel.gowthamvandana.com
< 
<html>
<head><title>308 Permanent Redirect</title></head>
<body>
<center><h1>308 Permanent Redirect</h1></center>
<hr><center>nginx</center>
</body>
</html>
* Connection #0 to host otel.gowthamvandana.com left intact
/ # 
/ # # Test HTTPS connection (usually port 443)
/ # curl -v https://otel.gowthamvandana.com
*   Trying 10.0.23.104:443...
* Connected to otel.gowthamvandana.com (10.0.23.104) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: none
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS alert, unknown CA (560):
* SSL certificate problem: self signed certificate
* Closing connection 0
curl: (60) SSL certificate problem: self signed certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
/ # # or specifically test the port
/ # curl -v https://otel.gowthamvandana.com:443
*   Trying 10.0.23.104:443...
* Connected to otel.gowthamvandana.com (10.0.23.104) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: none
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS alert, unknown CA (560):
* SSL certificate problem: self signed certificate
* Closing connection 0
curl: (60) SSL certificate problem: self signed certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```