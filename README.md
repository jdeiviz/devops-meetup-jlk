# devops-meetup-jlk
Jenkins Loves Kubernetes


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
    --set controller.service.type=NodePort
```

# Install Jenkins via Helm

https://github.com/helm/charts/tree/master/stable/jenkins

```bash
$ kubectl create namespace devops-meetup

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
    --set ingress.enabled=true --set ingress.hosts[0]=docker-registry.local 
```
