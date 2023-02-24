pipeline {
  agent { label 'maven' }
  stages {
  	stage ('Parameters') {
        steps {
            echo '---Parameters GIT HUB'
            echo "BRANCH_NAME: ${env.GIT_BRANCH.split("/")[1]}"
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
      post {
        always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
        }
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
      	withEnv(['SONAR_SCANNER_OPTS=-Djavax.net.ssl.trustStore=/var/jenkins_home/certificates/cacerts -Djavax.net.ssl.trustStorePassword=changeit']){
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
    }
    
    stage('Vulnerability Scan - Docker ') {
      steps {
        sh "mvn dependency-check:check"
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
	stage('Kubernetes Deployment - DEV') {
      steps {
        withKubeConfig([credentialsId: 'kubeconfig']) {
          sh "sed -i 's#replace#mampudia/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
          sh "kubectl apply -f k8s_deployment_service.yaml -n devsecops"
        }
      }
	}   
  }
}