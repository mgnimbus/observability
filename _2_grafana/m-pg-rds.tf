module "db" {
  source             = "terraform-aws-modules/rds/aws"
  create_db_instance = false

  identifier = "grafanadb"

  engine              = "postgres"
  engine_version      = "13.15"
  instance_class      = "db.t3.micro"
  allocated_storage   = 10
  publicly_accessible = true


  db_name  = "grafanadb"
  username = "grafanaadmin"
  port     = 5432
  password = "champion"

  subnet_ids             = data.terraform_remote_state.eks.outputs.database_subnets
  create_db_subnet_group = true
  vpc_security_group_ids = [module.postgres_rds_sg.security_group_id]

  create_db_option_group    = false
  create_db_parameter_group = false

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 0

  deletion_protection = false
  tags                = local.common_tags
}


module "postgres_rds_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = "${local.name}-rds-postgress-sg"
  description = "Security group for user-service with custom ports open within VPC, and PostgreSQL publicly open"
  vpc_id      = data.terraform_remote_state.eks.outputs.vpc_id
  # Ingress Rules & CIDR Blocks
  ingress_rules       = ["all-all"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  # Egress Rule - all-all open
  egress_rules = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      rule        = "postgresql-tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "PostgreSQL"
    },
  ]
  tags = local.common_tags
}
