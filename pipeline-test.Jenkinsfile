pipeline {
  agent {
    kubernetes {
      //cloud 'kubernetes'
      label 'kubectl'
      serviceAccount 'jenkins'
      containerTemplate {
        name 'kubectl'
        image 'lachlanevenson/k8s-kubectl:v1.13.1'
        ttyEnabled true
        command 'cat'
      }
    }
  }
  stages {
    stage('Run kubectl') {
        steps {
            container ('kubectl') {
                sh 'kubectl apply -f https://k8s.io/examples/application/deployment.yaml'
            }
        }
    }
  }
}
