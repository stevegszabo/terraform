resource "helm_release" "pro_bus_apps" {
  for_each         = local.gcp_instance_managed_clusters
  namespace        = local.gcp_instance_helm_namespace
  chart            = local.gcp_instance_helm_deployments["projects"]["chart"]
  version          = local.gcp_instance_helm_deployments["projects"]["version"]
  name             = format("%s-pro-bus-apps", each.key)
  repository       = local.gcp_instance_helm_repo
  timeout          = local.gcp_instance_helm_timeout
  create_namespace = local.gcp_instance_helm_create
  atomic           = local.gcp_instance_helm_atomic
  cleanup_on_fail  = local.gcp_instance_helm_cleanup
  lint             = local.gcp_instance_helm_lint
  wait             = local.gcp_instance_helm_wait
  depends_on       = [helm_release.base]

  values = [
    <<-EOF
    projects:
    - name: ${format("%s-bus-apps", each.key)}
      description: ${format("%s-bus-apps", each.key)}
      sourceRepos:
      - ${each.value["helm_repository_url"]}
      - ${each.value["app_repository_url"]}
      destinations:

      - namespace: app-01
        server: https://kubernetes.default.svc
      - namespace: app-02
        server: https://kubernetes.default.svc
      - namespace: app-03
        server: https://kubernetes.default.svc

      - namespace: app-01
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: app-02
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: app-03
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}

      clusterResourceWhitelist:
      - group: ''
        kind: 'Namespace'

      namespaceResourceWhitelist:
      - group: ''
        kind: 'ServiceAccount'
      - group: ''
        kind: 'Service'
      - group: 'apps'
        kind: 'Deployment'
      - group: 'networking.k8s.io'
        kind: 'NetworkPolicy'
      - group: 'networking.istio.io'
        kind: 'DestinationRule'
      - group: 'networking.istio.io'
        kind: 'Gateway'
      - group: 'networking.istio.io'
        kind: 'VirtualService'
      - group: 'security.istio.io'
        kind: 'PeerAuthentication'
      - group: 'security.istio.io'
        kind: 'AuthorizationPolicy'
      - group: 'argoproj.io'
        kind: 'Rollout'
      - group: 'argoproj.io'
        kind: 'AnalysisTemplate'
      - group: 'external-secrets.io'
        kind: 'ExternalSecret'
      - group: 'secrets.hashicorp.com'
        kind: 'VaultAuth'
      - group: 'secrets.hashicorp.com'
        kind: 'VaultStaticSecret'
    EOF
  ]
}

resource "helm_release" "pro_bus_apps_boot" {
  for_each         = local.gcp_instance_managed_clusters
  namespace        = local.gcp_instance_helm_namespace
  chart            = local.gcp_instance_helm_deployments["projects"]["chart"]
  version          = local.gcp_instance_helm_deployments["projects"]["version"]
  name             = format("%s-pro-bus-apps-boot", each.key)
  repository       = local.gcp_instance_helm_repo
  timeout          = local.gcp_instance_helm_timeout
  create_namespace = local.gcp_instance_helm_create
  atomic           = local.gcp_instance_helm_atomic
  cleanup_on_fail  = local.gcp_instance_helm_cleanup
  lint             = local.gcp_instance_helm_lint
  wait             = local.gcp_instance_helm_wait
  depends_on       = [helm_release.base]

  values = [
    <<-EOF
    projects:
    - name: ${format("%s-bus-apps-boot", each.key)}
      description: ${format("%s-bus-apps-boot", each.key)}
      sourceRepos:
      - ${each.value["app_repository_url"]}
      destinations:
      - namespace: ${local.gcp_instance_helm_namespace}
        server: https://kubernetes.default.svc
      clusterResourceBlacklist:
      - group: '*'
        kind: '*'
      namespaceResourceWhitelist:
      - group: 'argoproj.io'
        kind: 'Application'
    EOF
  ]
}

resource "helm_release" "bus-apps" {
  for_each         = local.gcp_instance_managed_clusters
  namespace        = local.gcp_instance_helm_namespace
  chart            = local.gcp_instance_helm_deployments["applications"]["chart"]
  version          = local.gcp_instance_helm_deployments["applications"]["version"]
  name             = format("%s-bus-apps", each.key)
  repository       = local.gcp_instance_helm_repo
  timeout          = local.gcp_instance_helm_timeout
  create_namespace = local.gcp_instance_helm_create
  atomic           = local.gcp_instance_helm_atomic
  cleanup_on_fail  = local.gcp_instance_helm_cleanup
  lint             = local.gcp_instance_helm_lint
  wait             = local.gcp_instance_helm_wait

  depends_on = [
    kubernetes_secret_v1.apps,
    kubernetes_secret_v1.clusters,
    helm_release.pro_bus_apps_boot,
    helm_release.pro_bus_apps,
    helm_release.tools,
    helm_release.tools_common
  ]

  values = [
    <<-EOF
    applications:
    - name: ${format("%s-bus-apps-boot", each.key)}
      project: ${format("%s-bus-apps-boot", each.key)}
      source:
        path: ${each.value["app_repository_path"]}
        repoURL: ${each.value["app_repository_url"]}
      destination:
        namespace: ${local.gcp_instance_helm_namespace}
        server: https://kubernetes.default.svc
      syncPolicy:
        automated:
          allowEmpty: true
          prune: true
          selfHeal: true
    EOF
  ]
}
