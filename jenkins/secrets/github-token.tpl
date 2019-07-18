apiVersion: v1
kind: Secret
metadata:
  name: github
  namespace: jenkinsloveskubernetes
  labels:
    "jenkins.io/credentials-type": "usernamePassword"
  annotations:
    "jenkins.io/credentials-description" : "GitHub Access Token"
type: Opaque
stringData:
  username: admin
  password: TOKEN
