# devops-meetup-jlk
Jenkins Loves Kubernetes

# Install Kubernetes

With kubeadm:
```bash
kubeadm init --config kubeadm/cluster-config.yaml

# Create privileged psp configuration to run system pods
kubectl create -f kubeadm/privileged-conf.yaml
```

With GKE:
```bash
gcloud beta container clusters create "jenkinsloveskubernetes" \
    --zone "europe-west2-a" --cluster-version "1.11.6-gke.6" --username "admin"  \
    --machine-type "n1-standard-1" --num-nodes "3" \
    --addons HorizontalPodAutoscaling,HttpLoadBalancing \
    --enable-autoupgrade --enable-autorepair \
    --enable-autoscaling --max-nodes "10" --min-nodes "3" \
    --enable-pod-security-policy

# create a public static ip to attach in ingress controller service
gcloud compute addresses create ingress-ip --region europe-west2

# obtain cluster admin role
kubectl create clusterrolebinding cluster-admin-binding \
--clusterrole cluster-admin --user <account>

# Create privileged psp configuration to run system pods
kubectl create -f gke/privileged-conf.yaml

#TODO permisos para gce
#https://medium.com/google-cloud/using-googles-private-container-registry-with-docker-1b470cf3f50a

sed -i "/PASSWORD/$(cat keyfile.json | base64 -w 0)" gke/docker-registry-credentials.tpl > gke/docker-registry-credentials.yaml
kubectl create -f gke/docker-registry-credentials.yaml
```

# Create namespaces
```bash
$ kubectl create namespace jenkinsloveskubernetes

# Create privileged psp configuration to run any pod on jenkinsloveskubernetes namespace
kubectl create -f psp/privileged-conf.yaml
```

# Install HELM
https://docs.helm.sh/using_helm/#installing-helm

```bash
$ kubectl apply -f helm/tiller-conf.yaml
$ helm init --service-account tiller
```

# Install Nginx Ingress Controller via Helm
https://github.com/helm/charts/tree/master/stable/nginx-ingress


With kubeadm:
```bash
$ helm install stable/nginx-ingress \
    --name ingress \
    --namespace kube-system \
    --set controller.kind=DaemonSet \
    --set controller.daemonset.useHostPort=true
```

With GKE:
```bash
$ helm install stable/nginx-ingress \
    --name ingress \
    --namespace kube-system \
    --set controller.replicaCount=2 \
    --set controller.service.externalTrafficPolicy=Local \
    --set controller.service.type=LoadBalancer \
    --set controller.service.loadBalancerIP=$(gcloud compute addresses describe ingress-ip --region europe-west2 --format="value(address)") 
```

# Install Docker Registry via Helm
## (Only with kubeadm installation)
https://github.com/helm/charts/tree/master/stable/docker-registry

```bash
$ helm install stable/docker-registry \
    --name docker-registry \
    --namespace kube-system \
    --set ingress.enabled=true \
    --set ingress.hosts[0]=docker-registry.$(gcloud compute addresses describe ingress-ip --region europe-west2 --format="value(address)").sslip.io
```

# Install Jenkins via Helm
https://github.com/helm/charts/tree/master/stable/jenkins

```bash
$ sed -i "/TOKEN/<your github token>" jenkins/secrets/github-token.tpl > secrets/docker-registry-credentials.yaml
$ kubectl create -f secrets/github-token.yaml

$ helm install stable/jenkins \
    --name jenkins \
    --namespace jenkinsloveskubernetes \
    --values jenkins/helm/values.yaml \
    --set Master.HostName=jenkins.$(gcloud compute addresses describe ingress-ip --region europe-west2 --format="value(address)").sslip.io

# Get your Jenkins password
$ printf $(kubectl get secret --namespace jenkinsloveskubernetes jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
```

Configure the Kubernetes plugin in Jenkins to use the following Service Account name jenkins using the following steps:
  - Create a Jenkins credential of type Kubernetes service account with service account name jenkins
  - Under configure Jenkins -- Update the credentials config in the cloud section to use the service account credential you created in the step above.

# Create the Test pipeline (pipeline-test.yaml)


# Include Croc-Hunter project

First of all, create a new "Pipeline" Job with a GitHub repository (where the croc-hunter code is pushed). 

Then, copy the "lachie83" Jenkinsfile in the Pipeline text box.

It is important to install the "pipeline-github-lib:1.0" in order to be able to install Jenkins Libraries from GitHub.


- ADD SCRIPT APPROVAL -> new groovy.json.JsonSlurperClassic y parseText java.lang.String
new groovy.json.JsonSlurperClassic

- GRANT "edit" ROLE TO JENKINS SA IN THE kube-system namespace with the "jenkins-sa-helm.yaml" file

- Changed Jenkinsfile.json to docker own credentials and added new Username/Password credentials to talk to docker hub.

# Configure KANIKO
```bash
kubectl delete -f psp/privileged-conf.yaml
kubectl create -f psp/restricted-conf.yaml
```
Test again and see how to fail with docker

git checkout more-secure


sudo docker login --username ctolon22 quay.io
Password: <ponerla>

Take config.json from /root/.docker/config.json

kubectl create secret generic reg-cred --from-file=config.json -n jenkinsloveskubernetes

# Assign PodSecurityPolicy to show that you cannot mount docker.sock

1. Assign Privileged PodSecurityPolicy to Kube-System (`kubectl create -f psp-config/privileged-config.yaml`) and to "jenkinsloveskubernetes" namespace (`kubectl create -f psp-config/dm-privileged-rb.yaml`). This will allow you to mount docker socket.

2. Run "master" pipeline in the croc-hunter project -> Using Docker Host Daemon

3. Remove "privileged" PSP from jenkinsloveskubernetes -> `kubectl delete -f psp-config/dm-privileged-rb.yaml`

4. Create the restricted PSP and dependencies (ClusterRole and Rolebinding in the jenkinsloveskubernetes namespace)-> `kubectl create -f psp-config/dm-psp-restricted.yaml` && `kubectl create -f psp-config/dm-psp-clusterrole.yaml` && `kubectl create -f psp-config/restricted-rb.yaml`

5. Run again "master" pipeline -> It will fail because lack of permissions to mount docker host daemon. (See Jenkins logs).

This force us to use other mechanism to build Docker image -> KANIKO