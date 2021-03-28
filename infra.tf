
########################### create vpc ##########################

resource "aws_vpc" "blog" {
  cidr_block       = var.vpc.cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc.name
  }
}


############################ create public subnets #####################


resource "aws_subnet" "public_subnets" {

  for_each = var.subnet_num

  vpc_id            = aws_vpc.blog.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc.cidr,var.vpc.subnet, each.value)
    map_public_ip_on_launch = true

    tags = {
    Name = "${var.vpc.name}-public-${each.value}"
  }
}


############################ create private subnets ######################

resource "aws_subnet" "private_subnets" {

  for_each = var.subnet_num

  vpc_id            = aws_vpc.blog.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc.cidr,var.vpc.subnet, length(var.subnet_num)+each.value)

    tags = {
    Name = "${var.vpc.name}-private-${each.value}"
  }
}



############################# create internet gateway #######################

resource "aws_internet_gateway" "blog-igw" {
    
  vpc_id = aws_vpc.blog.id

  tags = {
    Name = "${var.vpc.name}-igw"
  }
}

################################# create route table ##############################

resource "aws_route_table" "public" {
    
  vpc_id = aws_vpc.blog.id
    
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.blog-igw.id
  }

  tags = {
    Name = "${var.vpc.name}-public-route"
  }
    
}


##########################  elastic ip #######################################

resource "aws_eip" "eip" {
  vpc      = true
}

###################   create nat gateway ########################################

resource "aws_nat_gateway" "blog-ngw" {

  allocation_id = aws_eip.eip.id
  subnet_id     =  values(aws_subnet.public_subnets)[0]["id"]

  tags = {
    Name = "${var.vpc.name}-nat"
  }
}

############## route table for private ##############

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.blog.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.blog-ngw.id
  }

  tags = {
    Name = "${var.vpc.name}-route-private"
  }
}

################## route table assosiation public #################################

resource "aws_route_table_association" "public" {

  for_each = aws_subnet.public_subnets
    
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
    
}

################  route table assosiation private   ####################################

resource "aws_route_table_association" "private" {

  for_each = aws_subnet.private_subnets
    
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
    
}

##################  uploading key ##############################################

resource "aws_key_pair" "key" {
  key_name   = "server-key"
  public_key = var.basic.key
  }


#################   security groups #########################################


###----------------bastion security group------------- ####

resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "Allow ssh traffic"
  vpc_id      = aws_vpc.blog.id

  ingress {
    description = "allow ssh connection from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc.name}-bastion"
  }
}



###----------------webserver security group------------- ####


resource "aws_security_group" "webserver" {
  name        = "webserver"
  description = "allow traffic from bastion server,web traffic"
  vpc_id      = aws_vpc.blog.id

  ingress {
    description = "allow 443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "allow 80 from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow ssh connection from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }  

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc.name}-webserver"
  }
}

###----------------database security group------------- ####

resource "aws_security_group" "database" {
  name        = "database"
  description = "Allow 3306 from webserver and 22 from bastion"
  vpc_id      = aws_vpc.blog.id


    ingress {
    description = "allow 3306 from webserver"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.webserver.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc.name}-database"
  }
}






#################   bastion ##########################################################

resource "aws_instance" "bastion" {

  ami           = var.basic.amazon_linux_ami
  instance_type = var.basic.type
  subnet_id = values(aws_subnet.public_subnets)[1]["id"]
  vpc_security_group_ids= [aws_security_group.bastion.id ]
  key_name = aws_key_pair.key.key_name

  tags = {
    Name = "${var.vpc.name}-bastion"
  }
}

#################### pass variables to webserver userdata script ####################

data "template_file" "wordpress" {
  template = file("scripts/wordpress_setup.sh")
  vars = {

  db_address = aws_db_instance.db.address
  db_user = var.db.db_user
  db_name = var.db.db_name
  db_pass = var.db.db_pass
  db_port = var.db.db_port
  }
}


#################   webserver ##########################################################


resource "aws_instance" "webserver" {

  ami           = var.basic.ubuntu_ami
  instance_type = var.basic.type
  subnet_id = values(aws_subnet.public_subnets)[0]["id"]
  vpc_security_group_ids= [aws_security_group.webserver.id ]
  key_name = aws_key_pair.key.key_name
  user_data = data.template_file.wordpress.rendered

  tags = {
    Name = "${var.vpc.name}-webserver"
  }
}


#################   subnet group ###################################################


resource "aws_db_subnet_group" "blog" {
    
  name       = "blog"
  subnet_ids = [for value in aws_subnet.private_subnets : value.id]

  tags = {
    Name = "blog"
  }
}

#################  database server ############################################

resource "aws_db_instance" "db" {
  allocated_storage       = var.db.db_storage
  storage_type            = var.db.db_storage_type
  engine                  = var.db.db_engine
  engine_version          = var.db.db_engine_version 
  instance_class          = var.db.db_instance_class  
  backup_retention_period = 0
  max_allocated_storage   = 0
  availability_zone       = keys(var.subnet_num)[2]
  deletion_protection     = false
  multi_az                = false
  publicly_accessible     = false
  db_subnet_group_name    = aws_db_subnet_group.blog.id
  vpc_security_group_ids  = [ aws_security_group.database.id ]
  skip_final_snapshot     = true
   
  name                    = var.db.db_name
  port                    = var.db.db_port
  username                = var.db.db_user
  password                = var.db.db_pass
    
    
  tags                    = {
        Name = "blog-database"
  }
}

####################### outputs #####################

output "webserver_pub_ip" {
  value       = aws_instance.webserver.public_ip
}
