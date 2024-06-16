# module "db" {
#   source             = "terraform-aws-modules/rds/aws"
#   create_db_instance = false

#   identifier = "grafanadb"

#   engine              = "postgres"
#   engine_version      = "16.2"
#   instance_class      = "db.t3.micro"
#   allocated_storage   = 10
#   publicly_accessible = true


#   db_name  = "grafanadb"
#   username = "grafanaadmin"
#   port     = 5432
#   password = "champion"

#   subnet_ids             = data.terraform_remote_state.eks.outputs.public_subnets
#   create_db_subnet_group = true
#   vpc_security_group_ids = [module.postgres_rds_sg.security_group_id]

#   create_db_option_group    = false
#   create_db_parameter_group = false

#   maintenance_window      = "Mon:00:00-Mon:03:00"
#   backup_window           = "03:00-06:00"
#   backup_retention_period = 0
#   skip_final_snapshot     = true
#   deletion_protection     = false
#   tags                    = local.common_tags
# }


# module "postgres_rds_sg" {
#   source      = "terraform-aws-modules/security-group/aws"
#   name        = "${local.name}-rds-postgress-sg"
#   description = "Security group for user-service with custom ports open within VPC, and PostgreSQL publicly open"
#   vpc_id      = data.terraform_remote_state.eks.outputs.vpc_id
#   # Ingress Rules & CIDR Blocks
#   ingress_rules       = ["all-all"]
#   ingress_cidr_blocks = ["0.0.0.0/0"]
#   # Egress Rule - all-all open
#   egress_rules = ["all-all"]
#   ingress_with_cidr_blocks = [
#     {
#       rule        = "postgresql-tcp"
#       cidr_blocks = "0.0.0.0/0"
#       description = "PostgreSQL"
#     },
#   ]
#   tags = local.common_tags
# }

# resource "aws_db_instance" "default" {
#   allocated_storage    = 10
#   db_name              = "mydb"
#   engine               = "mysql"
#   engine_version       = "8.0"
#   instance_class       = "db.t3.micro"
#   username             = "foo"
#   password             = "foobarbaz"
#   parameter_group_name = "default.mysql8.0"
#   skip_final_snapshot  = true
# }

# terraform import aws_db_instance.default mydb-rds-instance

# aws_db_instance.default:
# resource "aws_db_instance" "default" {
#     address                               = "grafanadb.cla6qgm8wr69.us-east-1.rds.amazonaws.com"
#     allocated_storage                     = 10
#     arn                                   = "arn:aws:rds:us-east-1:058264194719:db:grafanadb"
#     auto_minor_version_upgrade            = true
#     availability_zone                     = "us-east-1a"
#     backup_retention_period               = 0
#     backup_target                         = "region"
#     backup_window                         = "03:21-03:51"
#     ca_cert_identifier                    = "rds-ca-rsa2048-g1"
#     copy_tags_to_snapshot                 = true
#     customer_owned_ip_enabled             = false
#     db_name                               = "grafanadb"
#     db_subnet_group_name                  = "default-vpc-04016e5fbcc07661d"
#     dedicated_log_volume                  = false
#     delete_automated_backups              = true
#     deletion_protection                   = false
#     domain_dns_ips                        = []
#     enabled_cloudwatch_logs_exports       = []
#     endpoint                              = "grafanadb.cla6qgm8wr69.us-east-1.rds.amazonaws.com:5432"
#     engine                                = "postgres"
#     engine_version                        = "16.2"
#     engine_version_actual                 = "16.2"
#     hosted_zone_id                        = "Z2R2ITUGPM61AM"
#     iam_database_authentication_enabled   = false
#     id                                    = "db-FQSENWP7HH5F7DKTQDEYA5NHMA"
#     identifier                            = "grafanadb"
#     instance_class                        = "db.t3.micro"
#     iops                                  = 0
#     kms_key_id                            = "arn:aws:kms:us-east-1:058264194719:key/3f2778b6-e18d-4756-ac86-8f9fe8f92c87"
#     license_model                         = "postgresql-license"
#     listener_endpoint                     = []
#     maintenance_window                    = "wed:06:18-wed:06:48"
#     master_user_secret                    = []
#     max_allocated_storage                 = 0
#     monitoring_interval                   = 0
#     multi_az                              = false
#     network_type                          = "IPV4"
#     option_group_name                     = "default:postgres-16"
#     parameter_group_name                  = "default.postgres16"
#     performance_insights_enabled          = false
#     performance_insights_retention_period = 0
#     port                                  = 5432
#     publicly_accessible                   = true
#     replicas                              = []
#     resource_id                           = "db-FQSENWP7HH5F7DKTQDEYA5NHMA"
#     skip_final_snapshot                   = true
#     status                                = "available"
#     storage_encrypted                     = true
#     storage_throughput                    = 0
#     storage_type                          = "gp2"
#     tags                                  = {}
#     tags_all                              = {}
#     username                              = "grafanaadmin"
#     vpc_security_group_ids                = [
#         "sg-0def2c8fa271ea4ec",
#     ]
# }
