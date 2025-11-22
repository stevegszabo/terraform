#cloud-config

manage_etc_hosts:  true
preserve_hostname: true
package_update:    true
package_upgrade:   true

packages:
- software-properties-common
- apt-transport-https
- ca-certificates
- gnupg-agent
- sysstat
- podman
- nginx
- nmap
- curl
- ncal
- dc
- jq

runcmd:

## gcloud
- curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/gcloud.gpg
- echo "deb [signed-by=/etc/apt/keyrings/gcloud.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/gcloud.list
- sudo apt-get update
- sudo apt-get install -y google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin

## kubectl
- curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubectl.gpg
- echo 'deb [signed-by=/etc/apt/keyrings/kubectl.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubectl.list
- sudo apt-get update
- sudo apt-get install -y kubectl

## helm
- curl -fsSL https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor -o /etc/apt/keyrings/helm.gpg
- echo "deb [signed-by=/etc/apt/keyrings/helm.gpg arch=$(dpkg --print-architecture)] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm.list
- sudo apt-get update
- sudo apt-get install -y helm

## hashicorp
- curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
- echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
- sudo apt-get update
- sudo apt-get install -y terraform vault
