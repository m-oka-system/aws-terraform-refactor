################################
# RDS
################################
resource "aws_db_subnet_group" "subnet" {
  name = "${var.prefix}-db-subnet"

  subnet_ids = aws_subnet.private.*.id
}

resource "aws_db_parameter_group" "mysql" {
  name   = "${var.prefix}-parameter-group"
  family = "mysql8.0"

  parameter {
    name         = "general_log"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "slow_query_log"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "long_query_time"
    value        = "0"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_output"
    value        = "FILE"
    apply_method = "immediate"
  }
}

resource "aws_db_option_group" "mysql" {
  name                 = "${var.prefix}-option-group"
  engine_name          = "mysql"
  major_engine_version = "8.0"

  option {
    option_name                    = "MEMCACHED"
    port                           = "11211"
    vpc_security_group_memberships = [aws_security_group.rds_sg.id]

    option_settings {
      name  = "BACKLOG_QUEUE_LIMIT"
      value = "1024"
    }

    option_settings {
      name  = "BINDING_PROTOCOL"
      value = "auto"
    }
  }
}

resource "aws_db_instance" "mysql" {
  engine                                = "mysql"
  engine_version                        = "8.0.20"
  license_model                         = "general-public-license"
  identifier                            = "${var.prefix}-db-instance"
  username                              = var.db_username
  password                              = var.db_password
  instance_class                        = "db.t3.medium"
  storage_type                          = "gp2"
  allocated_storage                     = 20
  max_allocated_storage                 = 100
  multi_az                              = true
  db_subnet_group_name                  = aws_db_subnet_group.subnet.name
  publicly_accessible                   = false
  vpc_security_group_ids                = [aws_security_group.rds_sg.id]
  port                                  = 3306
  iam_database_authentication_enabled   = false
  name                                  = "cloud"
  parameter_group_name                  = aws_db_parameter_group.mysql.name
  option_group_name                     = aws_db_option_group.mysql.name
  backup_retention_period               = 7
  backup_window                         = "19:00-20:00"
  copy_tags_to_snapshot                 = true
  storage_encrypted                     = true
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  monitoring_role_arn                   = "arn:aws:iam::${data.aws_caller_identity.self.account_id}:role/rds-monitoring-role"
  enabled_cloudwatch_logs_exports       = ["error", "general", "slowquery"]
  auto_minor_version_upgrade            = false
  maintenance_window                    = "Sat:20:00-Sat:21:00"
  deletion_protection                   = false
  skip_final_snapshot                   = true
  apply_immediately                     = false

  tags = {
    Name = "${var.prefix}-db-instance"
  }

  lifecycle {
    ignore_changes = [password]
  }
}

data "aws_caller_identity" "self" {}

output "rds_endpoint" {
  description = "The connection endpoint in address:port format."
  value       = aws_db_instance.mysql.endpoint
}
