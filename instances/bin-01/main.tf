terraform {
  cloud {
    organization = "organization"
    workspaces {
      name = "project-01-xxxxxx-bin-01"
    }
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
  }
}

provider "google" {
  project = local.gcp_instance_project
  region  = local.gcp_instance_region
}

locals {
  gcp_instance_project = "project-01-xxxxxx"
  gcp_instance_region  = "northamerica-northeast2"

  gcp_instance_common_images = [
    "auto",
    "cos-nvidia-installer:*",
    "gke-nvidia-installer:*",
    "k8s.gcr.io/metadata-proxy:*",
    "gcr.io/config-management-release/gatekeeper:*",
    "gcr.io/distroless/static",
    "gcr.io/gke-release/asm/install-cni:*",
    "gcr.io/gke-release/asm/mdp:*",
    "gcr.io/gke-release/asm/snk@*",
    "gcr.io/gke-release/asm/proxyv2:*",
    "gke.gcr.io/addon-resizer:*",
    "gke.gcr.io/antrea:*",
    "gke.gcr.io/cilium/cilium-win-multi:*",
    "gke.gcr.io/cilium/cilium:*",
    "gke.gcr.io/cluster-proportional-autoscaler:*",
    "gke.gcr.io/csi-node-driver-registrar:*",
    "gke.gcr.io/event-exporter:*",
    "gke.gcr.io/fastsocket-installer:*",
    "gke.gcr.io/fluent-bit-gke-exporter:*",
    "gke.gcr.io/fluent-bit:*",
    "gke.gcr.io/gcp-compute-persistent-disk-csi-driver:*",
    "gke.gcr.io/gke-distroless/bash:*",
    "gke.gcr.io/gke-metadata-server:*",
    "gke.gcr.io/gke-metrics-agent-windows:*",
    "gke.gcr.io/gke-metrics-agent:*",
    "gke.gcr.io/gke-metrics-collector:*",
    "gke.gcr.io/image-package-extractor:*",
    "gke.gcr.io/image-package-extractor-er-cleanup:*",
    "gke.gcr.io/ingress-gce-404-server-with-metrics:*",
    "gke.gcr.io/k8s-dns-dnsmasq-nanny:*",
    "gke.gcr.io/k8s-dns-kube-dns:*",
    "gke.gcr.io/k8s-dns-sidecar:*",
    "gke.gcr.io/kube-proxy-amd64:*",
    "gke.gcr.io/metrics-server:*",
    "gke.gcr.io/netd-init:*",
    "gke.gcr.io/netd:*",
    "gke.gcr.io/nvidia-gpu-device-plugin@*",
    "gke.gcr.io/nvidia-partition-gpu@*",
    "gke.gcr.io/pause@*",
    "gke.gcr.io/prometheus-engine/config-reloader:*",
    "gke.gcr.io/prometheus-engine/operator:*",
    "gke.gcr.io/prometheus-engine/prometheus:*",
    "gke.gcr.io/prometheus-engine/rule-evaluator:*",
    "gke.gcr.io/prometheus-to-sd:*",
    "gke.gcr.io/proxy-agent:*",
    "gke.gcr.io/tpu-device-plugin:*"
  ]

  gcp_instance_clusters = {
    gke-01 = {
      keyring   = "kms-01"
      cryptokey = "kms-01-attestor"
      images    = [
        format("%s-docker.pkg.dev/%s/gar-01/argoproj/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/argoprojlabs/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/akuity/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/brancz/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/chaos-mesh/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/dexidp/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/docker/library/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/dynatrace-marketplace-prod/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/dynatrace/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/linux/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/external-dns/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/external-secrets/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/grafana/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/hashicorp/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/ingress-nginx/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/jetstack/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/komodor-public/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/prometheus/*", local.gcp_instance_region, local.gcp_instance_project),
        format("%s-docker.pkg.dev/%s/gar-01/stakater/*", local.gcp_instance_region, local.gcp_instance_project)
      ]
    }
  }
}

module "bin" {
  source                     = "app.terraform.io/organization/bin/gcp"
  version                    = "1.1.0"
  gcp_instance_project       = local.gcp_instance_project
  gcp_instance_region        = local.gcp_instance_region
  gcp_instance_common_images = local.gcp_instance_common_images
  gcp_instance_clusters      = local.gcp_instance_clusters
}
