terraform {
  required_providers {
    cloudsmith = {
      source  = "cloudsmith-io/cloudsmith"
      version = "~> 0.0.87"
    }
  }
}

provider "cloudsmith" {}

data "cloudsmith_namespace" "current" {
  slug = "aidanoc15"
}

resource "cloudsmith_repository" "demo" {
  name            = "Terraform Technical Challenge"
  slug            = "terraform-technical-challenge"
  description     = "Repository managed with Terraform"
  namespace       = data.cloudsmith_namespace.current.slug_perm
  repository_type = "Private"
}

resource "cloudsmith_repository_upstream" "pypi" {
  name          = "PyPI"
  namespace     = data.cloudsmith_namespace.current.slug_perm
  repository    = cloudsmith_repository.demo.slug_perm
  upstream_type = "python"
  upstream_url  = "https://pypi.org/simple"
  mode          = "Cache and Proxy"
  is_active     = true
  verify_ssl    = true
}

resource "cloudsmith_repository_upstream" "dockerhub" {
  name          = "Docker Hub"
  namespace     = data.cloudsmith_namespace.current.slug_perm
  repository    = cloudsmith_repository.demo.slug_perm
  upstream_type = "docker"
  upstream_url  = "https://registry-1.docker.io"
  mode          = "Cache and Proxy"
  is_active     = true
  verify_ssl    = true
}

