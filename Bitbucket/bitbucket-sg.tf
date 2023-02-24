resource "aws_security_group" "bitbucket_instance_sg" {
  provider = aws.mgmt

  name        = "bitbucket_instance_sg"
  description = "Allow BitBucket traffic"
  vpc_id      = data.terraform_remote_state.network-mgmt.outputs.vpc_id

  ingress {
    from_port   = 7990
    protocol    = "tcp"
    to_port     = 7990
    cidr_blocks = ["${var.ip_network_mgmt}.0.0/16"]
  }
  #allows bamboo ssh access so that it can connect to bitbucket repos
  ingress {
    from_port   = 7999
    protocol    = "tcp"
    to_port     = 7999
    cidr_blocks = ["${var.ip_network_mgmt}.0.0/16"]
  }

  ingress {
    from_port   = 7992
    protocol    = "tcp"
    to_port     = 7992
    cidr_blocks = ["${var.ip_network_mgmt}.0.0/16"]
  }

  ingress {
    from_port   = 7993
    protocol    = "tcp"
    to_port     = 7993
    cidr_blocks = ["${var.ip_network_mgmt}.0.0/16"]
  }

  ingress {
    from_port = 8443
    protocol  = "tcp"
    to_port   = 8443
    cidr_blocks = [
      "${var.ip_network_mgmt}.0.0/16",
      "${var.ip_network_prod}.0.0/16",
      "${var.ip_network_stage}.0.0/16",
    ]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["${var.ip_network_mgmt}.0.0/16"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
}

resource "aws_security_group" "bitbucket_db_sg" {
  provider = aws.mgmt

  name        = "bitbucket_db_sg"
  vpc_id      = data.terraform_remote_state.network-mgmt.outputs.vpc_id
  description = "Allow BitBucket DB traffic"

  ingress {
    from_port = 5432
    protocol  = "tcp"
    to_port   = 5432
    security_groups = [
      aws_security_group.bitbucket_instance_sg.id,
      data.terraform_remote_state.nessusburp.outputs.nessusburp_instance_sg_id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bitbucket_opensearch_sg" {
  provider = aws.mgmt

  name        = "bitbucket_opensearch_sg"
  vpc_id      = data.terraform_remote_state.network-mgmt.outputs.vpc_id
  description = "Allow BitBucket Opensearch traffic"

  ingress {
    from_port = 9200
    protocol  = "tcp"
    to_port   = 9200
    security_groups = [
      aws_security_group.bitbucket_instance_sg.id
    ]
  }

  ingress {
    from_port = 9300
    protocol  = "tcp"
    to_port   = 9300
    security_groups = [
      aws_security_group.bitbucket_instance_sg.id
    ]
  }

  ingress {
    from_port = 443
    protocol  = "tcp"
    to_port   = 443
    security_groups = [
      aws_security_group.bitbucket_instance_sg.id
    ]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


