terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0.0"
    }
  }
}

#APP Mesh Config
resource "aws_appmesh_mesh" "tokyo_appmesh" {
  name = "tokyo-appmesh"

  spec {
    egress_filter {
      type = "ALLOW_ALL"
    }
  }
}

#App Mesh Virtual Router
resource "aws_appmesh_virtual_router" "tokyo_serviceb" {
  name      = "tokyo-serviceB"
  mesh_name = aws_appmesh_mesh.tokyo_appmesh.id

  spec {
    listener {
      port_mapping {
        port     = 8080
        protocol = "http"
      }
    }
  }
}

#App Mesh Virtual Node Config
resource "aws_appmesh_virtual_node" "tokyo_serviceb1" {
  name      = "tokyo-serviceBv1"
  mesh_name = aws_appmesh_mesh.tokyo_appmesh.id

  spec {
    backend {
      virtual_service {
        virtual_service_name = "tokyo.servicea.simpleapp.local"
      }
    }

    listener {
      port_mapping {
        port     = 8080
        protocol = "http"
      }
    }

    service_discovery {
      dns {
        hostname = "serviceb.simpleapp.local"        
      }
    }
  }
}
#App Mesh Route Config
resource "aws_appmesh_route" "tokyo-serviceb" {
  name                = "tokyo-serviceB-route"
  mesh_name           = aws_appmesh_mesh.tokyo_appmesh.id
  virtual_router_name = aws_appmesh_virtual_router.tokyo_serviceb.name

  spec {
    http_route {
      match {
        prefix = "/"
      }

      retry_policy {
        http_retry_events = [
          "server-error",
        ]
        max_retries = 1

        per_retry_timeout {
          unit  = "s"
          value = 15
        }
      }

      action {
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.tokyo_serviceb1.name
          weight       = 100
        }
      }
    }
  }
}

#App Mesh Virtual Service
resource "aws_appmesh_virtual_service" "tokyo_servicea" {
  name      = "tokyo.servicea.simpleapp.local"
  mesh_name = aws_appmesh_mesh.tokyo_appmesh.id

  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.tokyo_serviceb1.name
      }
    }
  }
}
#AppMesh with Virtual Gateway 
resource "aws_appmesh_virtual_gateway" "tokyo-example" {
  name      = "tokyo-example-virtual-gateway"
  mesh_name = "aws_appmesh_mesh.tokyo_appmesh.id"

  spec {
    listener {
      port_mapping {
        port     = 8080
        protocol = "http"
      }
    }
  }

  tags = {
    Environment = "test"
  }
}