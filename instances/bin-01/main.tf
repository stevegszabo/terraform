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
  gcp_instance_project  = "project-01-xxxxxx"
  gcp_instance_region   = "northamerica-northeast2"
  gcp_instance_registry = format("northamerica-northeast2-docker.pkg.dev/%s/gar-01", local.gcp_instance_project)

  gcp_instance_clusters = [
    {
      cluster   = "gke-01"
      keyring   = "kms-01"
      cryptokey = "kms-01-attestor"
    }
  ]

  gcp_instance_images = [
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
    "gke.gcr.io/tpu-device-plugin:*",
    format("%s/argoproj/*", local.gcp_instance_registry),
    format("%s/argoprojlabs/*", local.gcp_instance_registry),
    format("%s/akuity/*", local.gcp_instance_registry),
    format("%s/brancz/*", local.gcp_instance_registry),
    format("%s/chaos-mesh/*", local.gcp_instance_registry),
    format("%s/dexidp/*", local.gcp_instance_registry),
    format("%s/docker/library/*", local.gcp_instance_registry),
    format("%s/dynatrace-marketplace-prod/*", local.gcp_instance_registry),
    format("%s/dynatrace/*", local.gcp_instance_registry),
    format("%s/linux/*", local.gcp_instance_registry),
    format("%s/external-dns/*", local.gcp_instance_registry),
    format("%s/external-secrets/*", local.gcp_instance_registry),
    format("%s/grafana/*", local.gcp_instance_registry),
    format("%s/hashicorp/*", local.gcp_instance_registry),
    format("%s/ingress-nginx/*", local.gcp_instance_registry),
    format("%s/jetstack/*", local.gcp_instance_registry),
    format("%s/komodor-public/*", local.gcp_instance_registry),
    format("%s/prometheus/*", local.gcp_instance_registry),
    format("%s/stakater/*", local.gcp_instance_registry)
  ]
}

module "bin" {
  source                = "app.terraform.io/organization/bin/gcp"
  version               = "1.0.7"
  gcp_instance_region   = local.gcp_instance_region
  gcp_instance_clusters = local.gcp_instance_clusters
  gcp_instance_images   = local.gcp_instance_images
}
