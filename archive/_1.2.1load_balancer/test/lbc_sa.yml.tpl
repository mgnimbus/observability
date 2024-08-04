apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: ${irsa_lbc_role_arn}
  name: ${service_account_name}
  namespace: ${namespace}
