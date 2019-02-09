# devops-meetup-jlk
Jenkins Loves Kubernetes

Kubernetes installed with `kubeadm init --config cluster-config.yaml`

Create the "privileged" PSP configuration -> `kubectl create -f privileged-conf.yaml`

# Installing HELM
https://docs.helm.sh/using_helm/#installing-helm -> Scripted

```bash
$ kubectl apply -f tiller-conf.yaml

$ helm init --service-account tiller
```

# Install Nginx Ingress Controller via Helm

https://github.com/helm/charts/tree/master/stable/nginx-ingress

```bash
$ helm install stable/nginx-ingress \
    --name ingress \
    --namespace kube-system \
    --set controller.kind=DaemonSet \
    --set controller.daemonset.useHostPort=true
```

# Install Jenkins via Helm

https://github.com/helm/charts/tree/master/stable/jenkins

```bash
$ kubectl create namespace devops-meetup

# If using this 
$ helm inspect values stable/jenkins > helm/jenkins-values.yaml

$ helm install stable/jenkins \
    --name jenkins \
    --namespace devops-meetup \
    --values helm/jenkins-values.yaml

# Get your Jenkins password
printf $(kubectl get secret --namespace devops-meetup jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
```

Configure the Kubernetes plugin in Jenkins to use the following Service Account name jenkins using the following steps:
  - Create a Jenkins credential of type Kubernetes service account with service account name jenkins
  - Under configure Jenkins -- Update the credentials config in the cloud section to use the service account credential you created in the step above.

# Create the Test pipeline (pipeline-test.yaml)

# Install Docker Registry via Helm

https://github.com/helm/charts/tree/master/stable/docker-registry

```bash
$ helm install stable/docker-registry \
    --name docker-registry \
    --namespace kube-system \
    --set ingress.enabled=true --set ingress.hosts[0]=docker-registry.local \
    --set secrets.htpasswd=devops:$2y$05$CW3bI3CCAy.kJwdeeSNGZuDcwEJqTYlHM9wLmIYTsZXrjfGlxsJXi
```


# Include Croc-Hunter project

First of all, create a new "Pipeline" Job with a GitHub repository (where the croc-hunter code is pushed). 

Then, copy the "lachie83" Jenkinsfile in the Pipeline text box.

It is important to install the "pipeline-github-lib:1.0" in order to be able to install Jenkins Libraries from GitHub.


- ADD SCRIPT APPROVAL -> new groovy.json.JsonSlurperClassic y parseText java.lang.String
new groovy.json.JsonSlurperClassic

- GRANT "edit" ROLE TO JENKINS SA IN THE kube-system namespace with the "jenkins-sa-helm.yaml" file

- Changed Jenkinsfile.json to docker own credentials and added new Username/Password credentials to talk to docker hub.


# Configure KANIKO
sudo docker login --username ctolon22 quay.io
Password: <ponerla>

Take config.json from /root/.docker/config.json

kubectl create secret generic reg-cred --from-file=config.json -n devops-meetup

# Assign PodSecurityPolicy to show that you cannot mount docker.sock

kubectl create serviceaccount -n psp-example fake-user
kubectl create rolebinding -n psp-example fake-editor --clusterrole=edit --serviceaccount=psp-example:fake-user