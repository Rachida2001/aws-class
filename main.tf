# Define the latest Amazon Linux 2 AMI
data "aws_ami" "latest_amazon_linux_2" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  owners = ["amazon"]
}

# Define a security group for the Wordpress server
resource "aws_security_group" "wordpress_sg" {
  name        = "Wordpress-Server-SG"
  description = "Security group for Wordpress server"
  vpc_id      = var.vpc_id

  # Allow SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow MySQL access from EC2 instance
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow All Outbound Traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define a security group for the RDS database
resource "aws_security_group" "rds_sg" {
  name        = "RDS-Database-SG"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  depends_on = [aws_security_group.wordpress_sg]

  # Allow MySQL access from the EC2 instance
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress_sg.id]
  }
}



# Define a MySQL database instance for Wordpress
resource "aws_db_instance" "wordpress-db-mysql" {
  engine                 = "mysql"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_user_password
  multi_az               = true
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = "wordpress_db_subnet"
  tags = {
    Name = "Wordpress-db"
  }
}


resource "aws_db_subnet_group" "wordpress_db" {
  name       = "wordpress_db_subnet"
  subnet_ids = var.private_subnet_ids



  tags = {
    Name = "Wordpress_DB_subnet_group"
  }
}

output "db_RDS" {
  description = "Endpoint of the MySQL database"
  value       = aws_db_instance.wordpress-db-mysql.endpoint
}

# terraform apply -var="db_RDS=$(terraform output -raw db_RDS)"
# The above command will output the RDS endpoint into db_RDS variable.


# Define an IAM instance profile for SSM access
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSM-Instance-Profile"

  role = aws_iam_role.ssm_role.name
}

# Define an IAM role for SSM access
resource "aws_iam_role" "ssm_role" {
  name               = "SSM-Role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach an IAM policy to the SSM role
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm_role.name
}

# Define a template file for user data
// -----------------------------------------------
// Change USERDATA variable value after grabbing RDS endpoint info
// -----------------------------------------------
/*data "template_file" "user_data" {
  template = file("userdata.sh")
  vars = {
    db_username      = var.db_username
    db_user_password = var.db_user_password
    db_name          = var.db_name
    db_RDS           = var.db_RDS
  }
}*/

# Define an EC2 instance for the Wordpress server
resource "aws_instance" "Wordpress-Server" {
  ami                    = data.aws_ami.latest_amazon_linux_2.id
  instance_type          = "t2.micro"
  key_name               = "Pro-Core-Internship-Key"
  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.wordpress_sg.id]

  // Associate the IAM instance profile with the EC2 instance
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  #user_data            = data.template_file.user_data.rendered
  user_data = templatefile("user_data.sh", {
    db_username      = var.db_username
    db_user_password = var.db_user_password
    db_name          = var.db_name
    db_RDS           = var.db_RDS
  })


  tags = {
    Name = "Wordpress-Server"
  }

  depends_on = [
    aws_db_instance.wordpress-db-mysql,
  ]
}


# Allocate an Elastic IP for the Wordpress server
resource "aws_eip" "wordpress_eip" {
  domain                    = "standard"
  instance                  = aws_instance.Wordpress-Server.id
  associate_with_private_ip = aws_instance.Wordpress-Server.private_ip

  tags = {
    Name = "wordpress-server-eip"
  }
}
