pipeline {
  agent { label 'maven' }
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
    
    //    stage('Vulnerability Scan - Docker ') {
    //      steps {
    //         sh "mvn dependency-check:check"   
    //        }
    // }

    stage('Vulnerability Scan - Docker') {
      #agent { 
      #	label 'builnode'
      #}
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
          	sh 'cd $(pwd)'
            sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
          }
        )
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
		
	stage('Kubernetes Deployment - DEV') {
      steps {
        withKubeConfig([credentialsId: 'kubeconfig']) {
          sh "sed -i 's#replace#mampudia/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
          sh "kubectl apply -f k8s_deployment_service.yaml -n devsecops"
        }
      }
	}
  }
  post {
    always {
      junit 'target/surefire-reports/*.xml'
      jacoco execPattern: 'target/jacoco.exec'
      dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
    }
    // success {

    // }

    // failure {

    // }
  }  
}