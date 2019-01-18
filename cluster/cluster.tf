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
