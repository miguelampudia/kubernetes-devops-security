pipeline {
  agent { label 'maven' }
  environment {
    deploymentName = "devsecops"
    namespaceName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "mampudia/numeric-app:${GIT_COMMIT}"
    applicationURL = "http://devsecops-demo.eastus.cloudapp.azure.com/"
    applicationURI = "/increment/99"
  }
  stages {
  	stage ('Parameters') {
        steps {
            echo '---Parameters GIT HUB'
            echo "BRANCH_NAME: ${env.GIT_BRANCH.split("/")[1]}"
            sh "pwd"
        }
    }
  	stage('Build Artifact') {
        steps {
          sh "mvn clean package -DskipTests=true"
          archive 'target/*.jar' 
        }
  	}
  	stage('Unit Tests - JUnit and Jacoco') {
      steps {
        sh "mvn test"
      }
	}
	stage('Mutation Tests - PIT') {
      steps {
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
      }
      post {
        always {
          pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
        }
      }
	}
	stage('SonarQube - SAST') {
      steps {
		withSonarQubeEnv('sonarqube.ampudiacompany') {
        	sh "mvn clean verify sonar:sonar -Dsonar.projectKey=numeric-application"
	    }
	    timeout(time: 2, unit: 'MINUTES') {
        	script {
            	waitForQualityGate abortPipeline: true
  			}
        }
      }
    }

    stage('Vulnerability Scan - Docker') {
      agent { 
      	label 'builnode'
      }
      steps {
        parallel(
          "Dependency Scan": {
            sh "mvn dependency-check:check"
          },
          "Trivy Scan": {
            sh "bash /home/jenkins/trivy-docker-image-scan.sh"
          },
          "OPA Conftest": {
          	sh 'cp /home/jenkins/opa-docker-security.rego $(pwd)/opa-docker-security.rego'
            sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
          }
        )
      }
      post {
        always {
          dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
        }
      }
    }
        
	stage('Docker Build and Push') {
      steps {
        withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
          sh 'printenv'
          sh 'docker build -t mampudia/numeric-app:""$GIT_COMMIT"" .'
          sh 'docker push mampudia/numeric-app:""$GIT_COMMIT""'
        }
      }
	}
	
	
	
	stage('Vulnerability Scan - Kubernetes') {
	  agent { 
      	label 'builnode'
      }
      steps {
        parallel(
          "OPA Scan": {
            sh 'cp /home/jenkins/opa-k8s-security.rego $(pwd)/opa-k8s-security.rego'
          	sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
          },
          "Kubesec Scan": {
            sh "bash /home/jenkins/kubesec-scan.sh"
          }
        )
      }
    }
	
		
	//stage('Kubernetes Deployment - DEV') {
    //  steps {
    //    withKubeConfig([credentialsId: 'kubeconfig']) {
    //      sh "sed -i 's#replace#mampudia/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
    //      sh "kubectl apply -f k8s_deployment_service.yaml -n devsecops"
    //    }
    //  }
	//}
	
	stage('K8S Deployment - DEV') {
      steps {
        parallel(
          "Deployment": {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "bash /home/jenkins/k8s-deployment.sh"
            }
          },
          "Rollout Status": {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "bash /home/jenkins/k8s-deployment-rollout-status.sh"
            }
          }
        )
      }
    }
  }
  post {
    always {
      junit 'target/surefire-reports/*.xml'
      jacoco execPattern: 'target/jacoco.exec'
    }
    // success {

    // }

    // failure {

    // }
  }  
}