terraform {
  cloud {
    organization = "organization"
    workspaces {
      name = "project-01-xxxxxx-arg-01"
    }
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.34.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }
  }
}

provider "google" {
  project = local.gcp_instance_project
  region  = local.gcp_instance_region
}

provider "kubernetes" {
  host  = format("https://%s", data.google_container_cluster.controller.control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)
  token = data.google_client_config.this.access_token
}

provider "helm" {
  kubernetes {
    host  = format("https://%s", data.google_container_cluster.controller.control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)
    token = data.google_client_config.this.access_token
  }
}

locals {
  gcp_instance_region         = "northamerica-northeast2"
  gcp_instance_project        = "project-01-xxxxxx"
  gcp_instance_name           = "gke-01"

  gcp_instance_github_appid   = "9999999"
  gcp_instance_github_insid   = "99999999"
  gcp_instance_github_secret  = "argocd-github-private"

  gcp_instance_helm_repo      = "https://repository/"
  gcp_instance_helm_namespace = "base-argocd"
  gcp_instance_helm_timeout   = 180
  gcp_instance_helm_create    = true
  gcp_instance_helm_atomic    = true
  gcp_instance_helm_cleanup   = true
  gcp_instance_helm_lint      = true
  gcp_instance_helm_wait      = true

  gcp_instance_tools_repo = {
    name       = "repository-tools"
    url        = "https://github.com/tools.git"
    secret     = data.google_secret_manager_secret_version.this.secret_data
  }

  gcp_instance_apps_repo = {
    name       = "repository-apps"
    url        = "https://github.com/applications.git"
    secret     = data.google_secret_manager_secret_version.this.secret_data
  }

  gcp_instance_tools_common = {
    name                 = "common-eng"
    helm_repository_url  = local.gcp_instance_helm_repo
    tool_repository_url  = local.gcp_instance_tools_repo["url"]
    tool_repository_path = "engineering/common"
  }

  gcp_instance_managed_projects = {
    project-01-xxxxxx = [
      {
        cluster              = "gke-01"
        helm_repository_url  = local.gcp_instance_helm_repo
        tool_repository_url  = local.gcp_instance_tools_repo["url"]
        tool_repository_path = "engineering/project-01-xxxxxx/gke-01"
        app_repository_url   = local.gcp_instance_apps_repo["url"]
        app_repository_path  = "engineering/project-01-xxxxxx/gke-01"
      }
    ]
  }

  gcp_instance_managed_targets = [
    for index, value in local.gcp_instance_managed_projects : [
      for cluster in distinct(value) : {
        project               = index
        name                  = cluster["cluster"]
        helm_repository_url   = cluster["helm_repository_url"]
        tool_repository_url   = cluster["tool_repository_url"]
        tool_repository_path  = cluster["tool_repository_path"]
        app_repository_url    = cluster["app_repository_url"]
        app_repository_path   = cluster["app_repository_path"]
        cluster_resource_name = format("cluster-%s-%s", cluster["cluster"], index)
      }
    ]
  ]

  gcp_instance_managed_clusters = {
    for index, value in flatten(local.gcp_instance_managed_targets) :
      format("%s-%s", value["name"], value["project"]) => value
  }

  gcp_instance_helm_deployments = {
    base = {
      chart   = "argo-cd"
      version = "8.1.1"
    }

    projects = {
      chart   = "argocd-projects"
      version = "0.5.0"
    }

    applications = {
      chart   = "argocd-applications"
      version = "0.3.0"
    }
  }

  gcp_instance_argo_release = {
    ingress_enabled       = false
    ingress_domain        = "argo.domain.ca"
    ingress_cert_issuer   = "gke-01-staging-cert-manager-issuer"
    ingress_class_name    = "nginx"

    config_reconciliation = "120s"

    global_repository     = "northamerica-northeast2-docker.pkg.dev/project-01-xxxxxx/gar-01/argoproj/argocd"
    redis_repository      = "northamerica-northeast2-docker.pkg.dev/project-01-xxxxxx/gar-01/docker/library/redis"
    dex_repository        = "northamerica-northeast2-docker.pkg.dev/project-01-xxxxxx/gar-01/dexidp/dex"

    redis_ksa_name        = "gke-01-argocd-redis"
    redis_init_ksa_name   = "gke-01-argocd-redis-secret-init"
    dex_ksa_name          = "gke-01-argocd-dex-server"
    server_ksa_name       = "gke-01-argocd-server"
    application_ksa_name  = "gke-01-argocd-applicationset-controller"
    notification_ksa_name = "gke-01-argocd-notifications-controller"
    controller_ksa_name   = "gke-01-argocd-application-controller"

    server_gsa_name       = "gke-01-arg@project-01-xxxxxx.iam.gserviceaccount.com"
    controller_gsa_name   = "gke-01-arg@project-01-xxxxxx.iam.gserviceaccount.com"
  }
}

data "google_client_config" "this" {
}

data "google_container_cluster" "controller" {
  name = local.gcp_instance_name
}

data "google_container_cluster" "managed" {
  for_each = local.gcp_instance_managed_clusters
  project  = each.value["project"]
  name     = each.value["name"]
}

data "google_secret_manager_secret_version" "this" {
  secret = local.gcp_instance_github_secret
}

resource "kubernetes_secret_v1" "tools" {
  depends_on  = [helm_release.base]
  metadata {
    name      = local.gcp_instance_tools_repo["name"]
    namespace = local.gcp_instance_helm_namespace
    labels    = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  type = "Opaque"
  data = {
    type                    = "git"
    url                     = local.gcp_instance_tools_repo["url"]
    githubAppID             = local.gcp_instance_github_appid
    githubAppInstallationID = local.gcp_instance_github_insid
    githubAppPrivateKey     = local.gcp_instance_tools_repo["secret"]
  }
}

resource "kubernetes_secret_v1" "apps" {
  depends_on  = [helm_release.base]
  metadata {
    name      = local.gcp_instance_apps_repo["name"]
    namespace = local.gcp_instance_helm_namespace
    labels    = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  type = "Opaque"
  data = {
    type                    = "git"
    url                     = local.gcp_instance_apps_repo["url"]
    githubAppID             = local.gcp_instance_github_appid
    githubAppInstallationID = local.gcp_instance_github_insid
    githubAppPrivateKey     = local.gcp_instance_apps_repo["secret"]
  }
}

resource "kubernetes_secret_v1" "clusters" {
  for_each    = local.gcp_instance_managed_clusters
  depends_on  = [helm_release.base]
  metadata {
    name      = each.value["cluster_resource_name"]
    namespace = local.gcp_instance_helm_namespace
    labels    = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }
  type = "Opaque"
  data = {
    name   = each.value["cluster_resource_name"]
    server = format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)
    config = <<-EOF
    {
      "execProviderConfig": {
        "command": "argocd-k8s-auth",
        "args": ["gcp"],
        "apiVersion": "client.authentication.k8s.io/v1beta1"
      }
    }
    EOF
  }
}

resource "helm_release" "base" {
  namespace        = local.gcp_instance_helm_namespace
  chart            = local.gcp_instance_helm_deployments["base"]["chart"]
  version          = local.gcp_instance_helm_deployments["base"]["version"]
  name             = local.gcp_instance_name
  repository       = local.gcp_instance_helm_repo
  timeout          = local.gcp_instance_helm_timeout
  create_namespace = local.gcp_instance_helm_create
  atomic           = local.gcp_instance_helm_atomic
  cleanup_on_fail  = local.gcp_instance_helm_cleanup
  lint             = local.gcp_instance_helm_lint
  wait             = local.gcp_instance_helm_wait

  values = [
    <<-EOF
    global:
      domain: ${local.gcp_instance_argo_release["ingress_domain"]}
      image:
        repository: ${local.gcp_instance_argo_release["global_repository"]}
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
        runAsGroup: 999
    configs:
      cm:
        timeout.reconciliation: ${local.gcp_instance_argo_release["config_reconciliation"]}
      params:
        server.insecure: ${local.gcp_instance_argo_release["ingress_enabled"]}
    controller:
      serviceAccount:
        create: true
        name: ${local.gcp_instance_argo_release["controller_ksa_name"]}
        annotations:
          iam.gke.io/gcp-service-account: ${local.gcp_instance_argo_release["controller_gsa_name"]}
    dex:
      image:
        repository: ${local.gcp_instance_argo_release["dex_repository"]}
      serviceAccount:
        create: true
        name: ${local.gcp_instance_argo_release["dex_ksa_name"]}
    redis:
      image:
        repository: ${local.gcp_instance_argo_release["redis_repository"]}
      serviceAccount:
        create: true
        name: ${local.gcp_instance_argo_release["redis_ksa_name"]}
      containerSecurityContext:
        runAsUser: 999
        runAsGroup: 1000
    redisSecretInit:
      serviceAccount:
        create: true
        name: ${local.gcp_instance_argo_release["redis_init_ksa_name"]}
    server:
      serviceAccount:
        create: true
        name: ${local.gcp_instance_argo_release["server_ksa_name"]}
        annotations:
          iam.gke.io/gcp-service-account: ${local.gcp_instance_argo_release["server_gsa_name"]}
      ingress:
        enabled: ${local.gcp_instance_argo_release["ingress_enabled"]}
        tls: ${local.gcp_instance_argo_release["ingress_enabled"]}
        ingressClassName: ${local.gcp_instance_argo_release["ingress_class_name"]}
        annotations:
          cert-manager.io/cluster-issuer: ${local.gcp_instance_argo_release["ingress_cert_issuer"]}
    applicationSet:
      serviceAccount:
        create: true
        name: ${local.gcp_instance_argo_release["application_ksa_name"]}
    notifications:
      serviceAccount:
        create: true
        name: ${local.gcp_instance_argo_release["notification_ksa_name"]}
    EOF
  ]
}
