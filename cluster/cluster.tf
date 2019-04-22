resource "google_container_cluster" "gke-cluster" {
  name               = "gke-cluster-1"
  network            = "claranet-test"
  zone               = "europe-west1-b"
  initial_node_count = 1
  node_config {
        oauth_scopes = [
          "https://www.googleapis.com/auth/compute",
          "https://www.googleapis.com/auth/devstorage.read_only",
          "https://www.googleapis.com/auth/logging.write",
          "https://www.googleapis.com/auth/monitoring",
        ]
        labels {
            this-is-for = "dev-cluster"
        }
        tags = ["jenkins", "ssh", "http-server"]
    }
}

  
module "gce-lb-http1" {
  source            = "GoogleCloudPlatform/lb-http/google"
  name              = "group1-http-lb"
  target_tags       = "${module.mig1.target_tags}"

backends          = {
    "0" =
      { group = "${module.mig1.instance_group}" }
    ,
  }


  backend_params    = [
    # health check path, port name, port number, timeout seconds.
    "/health_check,http,80,10"
  ]
}
