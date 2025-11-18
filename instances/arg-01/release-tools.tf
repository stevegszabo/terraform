resource "helm_release" "pro_tools" {
  for_each         = local.gcp_instance_managed_clusters
  namespace        = local.gcp_instance_helm_namespace
  chart            = local.gcp_instance_helm_deployments["projects"]["chart"]
  version          = local.gcp_instance_helm_deployments["projects"]["version"]
  name             = format("%s-pro-tools", each.key)
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
    - name: ${format("%s-tools", each.key)}
      description: ${format("%s-tools", each.key)}
      sourceRepos:
      - ${each.value["helm_repository_url"]}
      destinations:

      - namespace: kube-system
        server: https://kubernetes.default.svc
      - namespace: base-cm
        server: https://kubernetes.default.svc
      - namespace: base-edns
        server: https://kubernetes.default.svc
      - namespace: base-eso
        server: https://kubernetes.default.svc
      - namespace: base-reload
        server: https://kubernetes.default.svc
      - namespace: base-nginx
        server: https://kubernetes.default.svc
      - namespace: base-argocd
        server: https://kubernetes.default.svc
      - namespace: base-istio
        server: https://kubernetes.default.svc
      - namespace: base-prometheus
        server: https://kubernetes.default.svc
      - namespace: base-vault
        server: https://kubernetes.default.svc
      - namespace: base-vso
        server: https://kubernetes.default.svc
      - namespace: base-grafana
        server: https://kubernetes.default.svc
      - namespace: base-dtrace
        server: https://kubernetes.default.svc
      - namespace: base-kargo
        server: https://kubernetes.default.svc

      - namespace: kube-system
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: base-cm
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: base-edns
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: base-eso
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: base-reload
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: base-nginx
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: base-argocd
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: base-istio
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: base-prometheus
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: base-vault
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: base-vso
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: base-grafana
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: base-dtrace
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}
      - namespace: base-kargo
        server: ${format("https://%s", data.google_container_cluster.managed[each.key].control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint)}

      clusterResourceWhitelist:
      - group: '*'
        kind: '*'
      namespaceResourceWhitelist:
      - group: '*'
        kind: '*'
    EOF
  ]
}

resource "helm_release" "pro_tools_boot" {
  for_each         = local.gcp_instance_managed_clusters
  namespace        = local.gcp_instance_helm_namespace
  chart            = local.gcp_instance_helm_deployments["projects"]["chart"]
  version          = local.gcp_instance_helm_deployments["projects"]["version"]
  name             = format("%s-pro-tools-boot", each.key)
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
    - name: ${format("%s-tools-boot", each.key)}
      description: ${format("%s-tools-boot", each.key)}
      sourceRepos:
      - ${each.value["tool_repository_url"]}
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

resource "helm_release" "pro_tools_boot_common" {
  namespace        = local.gcp_instance_helm_namespace
  chart            = local.gcp_instance_helm_deployments["projects"]["chart"]
  version          = local.gcp_instance_helm_deployments["projects"]["version"]
  name             = format("%s-pro-tools-boot", local.gcp_instance_tools_common["name"])
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
    - name: ${format("%s-tools-boot", local.gcp_instance_tools_common["name"])}
      description: ${format("%s-tools-boot", local.gcp_instance_tools_common["name"])}
      sourceRepos:
      - ${local.gcp_instance_tools_common["tool_repository_url"]}
      destinations:
      - namespace: ${local.gcp_instance_helm_namespace}
        server: https://kubernetes.default.svc
      clusterResourceBlacklist:
      - group: '*'
        kind: '*'
      namespaceResourceWhitelist:
      - group: 'argoproj.io'
        kind: 'ApplicationSet'
    EOF
  ]
}

resource "helm_release" "tools" {
  for_each         = local.gcp_instance_managed_clusters
  namespace        = local.gcp_instance_helm_namespace
  chart            = local.gcp_instance_helm_deployments["applications"]["chart"]
  version          = local.gcp_instance_helm_deployments["applications"]["version"]
  name             = format("%s-tools", each.key)
  repository       = local.gcp_instance_helm_repo
  timeout          = local.gcp_instance_helm_timeout
  create_namespace = local.gcp_instance_helm_create
  atomic           = local.gcp_instance_helm_atomic
  cleanup_on_fail  = local.gcp_instance_helm_cleanup
  lint             = local.gcp_instance_helm_lint
  wait             = local.gcp_instance_helm_wait

  depends_on = [
    kubernetes_secret_v1.tools,
    kubernetes_secret_v1.clusters,
    helm_release.pro_tools_boot,
    helm_release.pro_tools
  ]

  values = [
    <<-EOF
    applications:
    - name: ${format("%s-tools-boot", each.key)}
      project: ${format("%s-tools-boot", each.key)}
      source:
        path: ${each.value["tool_repository_path"]}
        repoURL: ${each.value["tool_repository_url"]}
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

resource "helm_release" "tools_common" {
  namespace        = local.gcp_instance_helm_namespace
  chart            = local.gcp_instance_helm_deployments["applications"]["chart"]
  version          = local.gcp_instance_helm_deployments["applications"]["version"]
  name             = format("%s-tools", local.gcp_instance_tools_common["name"])
  repository       = local.gcp_instance_helm_repo
  timeout          = local.gcp_instance_helm_timeout
  create_namespace = local.gcp_instance_helm_create
  atomic           = local.gcp_instance_helm_atomic
  cleanup_on_fail  = local.gcp_instance_helm_cleanup
  lint             = local.gcp_instance_helm_lint
  wait             = local.gcp_instance_helm_wait

  depends_on = [
    kubernetes_secret_v1.tools,
    kubernetes_secret_v1.clusters,
    helm_release.pro_tools_boot,
    helm_release.pro_tools_boot_common,
    helm_release.pro_tools
  ]

  values = [
    <<-EOF
    applications:
    - name: ${format("%s-tools-boot", local.gcp_instance_tools_common["name"])}
      project: ${format("%s-tools-boot", local.gcp_instance_tools_common["name"])}
      source:
        path: ${local.gcp_instance_tools_common["tool_repository_path"]}
        repoURL: ${local.gcp_instance_tools_common["tool_repository_url"]}
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
