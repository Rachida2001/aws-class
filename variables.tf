variable "public_subnet_ids" {
  type    = list(string)
  default = []
}

variable "private_subnet_ids" {
  type    = list(string)
  default = []
}

variable "vpc_id" {
  type    = string
  default = "vpc-0933c4272fcffaf39"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "muridi"
}


variable "db_user_password" {
  description = "Database user password"
  type        = string
  default     = "Welcome2VITI!"
}



variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "wordpressdb"
}

variable "db_RDS" {
  description = "Endpoint of the MySQL database"
  type        = string
  default     = "terraform-20230619233227028300000002.cjpdtyhimfza.us-east-1.rds.amazonaws.com:3306"
}
