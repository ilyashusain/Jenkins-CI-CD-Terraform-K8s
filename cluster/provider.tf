provider "google" {
  credentials = "${file("~/creds/serviceaccount.json")}"
  project     = "clarapcp-ea-ilyas-husein"
  region      = "europe-west1"
}
