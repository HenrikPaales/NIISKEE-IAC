terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  credentials = file("key.json")

  project = "niisk-ee"
  region  = "europe-north1"
  zone    = "europe-north1-a"
}

resource "google_compute_network" "vpc_network" {
  name = "niisk-network"
}

// Create cloud run service in europe-north1 region
resource "google_cloud_run_service" "service" {
  name     = "niisk-cloud-run"
  location = "europe-north1"

  template {
    spec {
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.service.location
  project     = google_cloud_run_service.service.project
  service     = google_cloud_run_service.service.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

// map domain niisk.ee to cloud run service
resource "google_cloud_run_domain_mapping" "service" {
  location = "europe-north1"
  name     = "niisk.ee"

  metadata {
    namespace = "niisk-ee"
  }

  spec {
    route_name = google_cloud_run_service.service.name
  }
}

