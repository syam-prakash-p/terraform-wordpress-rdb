
Crating new infra for wordpress server and setup wordpress in aws using terraform
-----------------------------------------------------------------------------------
 
* Create a new vpc
* Create public and private subnets
* Create a new internet gateway, route table for public subnets
* Attach the internet gateway with the route table.
* Allocate new elastic ip and using that elastic ip  create a new nat gateway and route table for private subnets
* Attach the nat gateway with the route table.
* Associate public subnets with public route table
* Associate private subnets with private route table
* Uploading already generated public key to aws
* Creating security group for bastion that allows ssh connection from everywhere
* Creating security group for web server ( wordpress server )  that allows ssh connection from bastion and http connection from everywhere
* Creating a security group for the database that allows connection form web server.
* Creating a bastion server,  web server ( wordpress server  using userdata script) and database server ( RDS)





