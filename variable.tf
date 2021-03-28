########## variables  #############

variable "vpc"{

	type = map
	default = {

	"cidr" = "172.20.0.0/16"
	"name" = "blog"
	"subnet" = 3
	}
}

variable "subnet_num" {

	type = map
    default     = {
    "us-east-2a" = 1
    "us-east-2b" = 2
    "us-east-2c" = 3
    
  }
}


variable "db"{
	
	type = map
	default = {

	db_user = "wpuser"
	db_name = "wordpress"
	db_pass = "wpuser2020"
	db_port = 3306
	db_storage = 20
    db_storage_type = "gp2"
    db_engine  = "mysql"
    db_engine_version = "5.7"
    db_instance_class = "db.t2.micro"

	}
}

variable "basic"{
type = map
default = {
"key" = "< put your public_key_file_content here >" 

"ubuntu_ami" = "ami-08962a4068733a2b6"
"amazon_linux_ami" = "ami-09246ddb00c7c4fef"
"type" = "t2.micro"
}
}