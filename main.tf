variable "grafana_admin_password" {
  type        = string
  description = "Mot de passe admin Grafana"
}

terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

provider "docker" {}

resource "docker_network" "monitoring" {
  name = "monitoring-network"
}

########################
# NGINX
########################

resource "docker_image" "nginx" {
  name = "nginx:latest"
}

resource "docker_container" "web" {
  name  = "web"
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 80
    external = 8080
  }
}

########################
# NODE EXPORTER
########################

resource "docker_image" "node_exporter" {
  name = "prom/node-exporter"
}

resource "docker_container" "node_exporter" {
  name  = "node-exporter"
  image = docker_image.node_exporter.image_id

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 9100
    external = 9100
  }
}

########################
# PROMETHEUS
########################

resource "docker_image" "prometheus" {
  name = "prom/prometheus"
}

resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = docker_image.prometheus.image_id

  networks_advanced {
    name = docker_network.monitoring.name
  }

  volumes {
    host_path      = "/root/devops-project/terraform/prometheus"
    container_path = "/etc/prometheus"
  }

  ports {
    internal = 9090
    external = 9090
  }
}

########################
# GRAFANA IMAGE
########################

resource "docker_image" "grafana" {
  name = "grafana/grafana"
}

########################
# GRAFANA
########################

resource "docker_container" "grafana" {
  name  = "grafana"
  image = docker_image.grafana.image_id

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 3000
    external = 3000
  }

  env = [
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}"
  ]
}


########################
# SURICATA
########################

resource "docker_image" "suricata" {
  name = "jasonish/suricata:latest"
}

resource "docker_container" "suricata" {

  name = "suricata"

  image = docker_image.suricata.image_id

  command = [
    "-i",
    "eth0"
  ]

  networks_advanced {
    name = docker_network.monitoring.name
  }

  capabilities {
    add = ["NET_ADMIN", "NET_RAW"]
  }

  volumes {
    host_path      = "/root/devops-project/terraform/suricata/logs"
    container_path = "/var/log/suricata"
  }

  volumes {
    host_path      = "/root/devops-project/terraform/suricata/rules"
    container_path = "/var/lib/suricata/rules"
  }

}

########################
# LOKI
########################

resource "docker_image" "loki" {
  name = "grafana/loki"
}

resource "docker_container" "loki" {

  name = "loki"

  image = docker_image.loki.image_id

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 3100
    external = 3100
  }

}

########################
# PROMTAIL
########################

resource "docker_image" "promtail" {
  name = "grafana/promtail"
}

resource "docker_container" "promtail" {

  name = "promtail"

  image = docker_image.promtail.image_id

  networks_advanced {
    name = docker_network.monitoring.name
  }

  volumes {

    host_path      = "/root/devops-project/terraform/promtail"
    container_path = "/etc/promtail"

  }

  volumes {

    host_path      = "/root/devops-project/terraform/suricata/logs"
    container_path = "/var/log/suricata"

  }

  command = [

    "-config.file=/etc/promtail/promtail-config.yml"

  ]

}
