# Provider
provider "google" {

  credentials = file("~/.ssh/aliproj001-8464fb05c270.json")
  project = "aliproj001"
  region  = "us-central1"
}

terraform {
  backend "gcs" {
    bucket = "terraform-state-data-1"
    prefix = "terraform-k8s-cluster-state"
    credentials = "~/.ssh/aliproj001-8464fb05c270.json"

   }
}


# Variables

variable "ssh_user" {
 
  default = "root" 
}

variable "ssh_key" {

  default = "~/.ssh/gcp_k8s.pub" 
}

variable "gce_zone" {
  
  type = string
}

# variable "gce_region" {
  
#   type = "string"
# }

# variable "gce_proj" {
  
#   type = "string"
# }



#########################
# Network Configuration #
#########################

resource "google_compute_network" "default" {
  name                    = "k8s-cluster-vpc-1"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "default" {
  name          = "k8s-subnet"
  ip_cidr_range = "10.240.0.0/24"
  network       = google_compute_network.default.name
}



##################
# Firewall rules #
##################

resource "google_compute_firewall" "external" {
  name    = "k8s-cluster-firewall-external"
  network = google_compute_network.default.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }

  allow {
    protocol = "udp"
  }


  source_ranges = [ "0.0.0.0/0" ]
}


resource "google_compute_firewall" "internal" {
  name    = "k8s-cluster-firewall-internal"
  network = google_compute_network.default.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    # ports    = ["80", "8080", "1000-2000"]
  }

  allow {
    protocol = "udp"
  }


  source_ranges = [ "10.240.0.0/24", "10.200.0.0/16" ]
}

resource "google_compute_address" "default" {
  name = "k8s-address"
}

####################
# Virtual machines #
####################

resource "google_compute_instance" "control-plane" {
  
  count = 3
  
  name         = "master-${count.index}"
  machine_type = "e2-small"
  zone = var.gce_zone
  can_ip_forward = true

  tags = ["master", "controller", "cluster1", "kubernetes"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

#   scratch_disk {
#   }

  network_interface {
    subnetwork = google_compute_subnetwork.default.name
    network_ip = "10.240.0.1${count.index}"
    access_config {
    }  
  }

  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${file(var.ssh_key)}"
  }

  metadata_startup_script = "apt-get install -y python"

}

resource "google_compute_instance" "workers" {
  
  count = 3
  
  name         = "worker-${count.index}"
  machine_type = "e2-small"
  zone = var.gce_zone
  can_ip_forward = true

  tags = [ "worker", "cluster1", "kubernetes" ]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

#   scratch_disk {
#   }

  network_interface {
    subnetwork = google_compute_subnetwork.default.name
    network_ip = "10.240.0.2${count.index}"
    access_config {
    }  
  }

  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${file(var.ssh_key)}"
  }

  metadata_startup_script = "apt-get install -y python"

}



# Load Balancer