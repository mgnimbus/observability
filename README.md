## 

```
ping otel.gowthamvandana.com

nslookup otel.gowthamvandana.com


dig otel.gowthamvandana.com

```



## Debugging Route53 
```bash
 aws route53 list-hosted-zones-by-name --dns-name gowthamvandana.com

# /hostedzone/Z04338881KRW1EL6YAQ5P

aws route53 list-resource-record-sets --hosted-zone-id /hostedzone/Z04338881KRW1EL6YAQ5P

aws route53 get-hosted-zone --id Z04338881KRW1EL6YAQ5P

# check whether its connected to right VPC


```