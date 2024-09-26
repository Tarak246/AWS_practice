resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "sub1" {
  vpc_id =  aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "sub2" {
  vpc_id =  aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id
}
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  } 
}
resource "aws_route_table_association" "rt1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}
resource "aws_route_table_association" "rt2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.RT.id
}
resource "aws_security_group" "mysg" {
  name        = "sample_SG"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id
  ingress {
    description = "allow http"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "allow ssh"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol       = "-1"
 }
}
resource "aws_s3_bucket" "sample_s3" {
  bucket = "mirrorworld1437"
}
resource "aws_instance" "web1" {
  ami           = "ami-0e86e20dae9224db8"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.mysg.id ]
  subnet_id = aws_subnet.sub1.id
  user_data = base64encode(file("userdata.sh"))
}
resource "aws_instance" "web2" {
  ami           = "ami-0e86e20dae9224db8"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.mysg.id ]
  subnet_id = aws_subnet.sub2.id
  user_data = base64encode(file("userdata1.sh"))
}
resource "aws_lb" "LB" {
  name               = "Alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mysg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]  
}
resource "aws_lb_target_group" "TG1" {
    name = "mytg"
    port = 80
    protocol = "HTTP"  
    vpc_id = aws_vpc.myvpc.id
    health_check {
      
    path = "/"
    port = "traffic-port"
    
    }
}
resource "aws_lb_target_group_attachment" "At1" {
    target_group_arn = aws_lb_target_group.TG1.arn
    target_id = aws_instance.web1.id
    port = 80 
}
resource "aws_lb_target_group_attachment" "At2" {
    target_group_arn = aws_lb_target_group.TG1.arn
    target_id = aws_instance.web2.id
    port = 80 
}
resource "aws_lb_listener" "lsnr" {
    load_balancer_arn = aws_lb.LB.id
    port = 80
    protocol = "HTTP"
    default_action {
      target_group_arn = aws_lb_target_group.TG1.arn
      type = "forward"
    } 
}
output "LBdns" {
    value = aws_lb.LB.dns_name  
}



