pipeline {
	agent { label 'maven' }
	environment {
		deploymentName = "devsecops"
		namespaceName = "devsecops"
	    containerName = "devsecops-container"
	    serviceName = "devsecops-svc"
	    imageName = "mampudia/numeric-app:${GIT_COMMIT}"
	    applicationURL = "https://udemy-devsecops.ampudiacompany.com/numeric"
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
		            	sh "bash trivy-docker-image-scan.sh"
		          	},
		          	"OPA Conftest": {
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
		
		stage('kubesec Scan - Kubernetes') {
	      	steps {
	        	sh "bash kubesec-scan.sh"
	      	}
	    }
	    
		stage('Vulnerability Scan - Kubernetes') {
			agent { 
	      		label 'builnode'
	      	}
	      	steps {
	        	parallel(
	          		"OPA Scan": {
	          			sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
	          		},
	          		"Trivy Scan": {
	            		sh "bash trivy-k8s-scan.sh"
	          		}
	        	)
	      	}
	    }	
		stage('K8S Deployment - DEV') {
	    	steps {
	        	parallel(
	          		"Deployment": {
	            		withKubeConfig([credentialsId: 'kubeconfig']) {
	              			sh "bash k8s-deployment.sh"
	            		}
	          		},
	          		"Rollout Status": {
	            		withKubeConfig([credentialsId: 'kubeconfig']) {
	              			sh "bash k8s-deployment-rollout-status.sh"
	            		}
	          		}
	        	)
	    	}
	    }
	    stage('Integration Tests - DEV') {
			steps {
				script {
		        	try {
		          		withKubeConfig([credentialsId: 'kubeconfig']) {
		            		sh "bash integration-test.sh"
		          		}
		        	} catch (e) {
		          		withKubeConfig([credentialsId: 'kubeconfig']) {
		            		sh "kubectl -n $imageName rollout undo deploy ${deploymentName}"
		          		}
		          	throw e
		        	}
		      	}
		    }
		}
		stage('OWASP ZAP - DAST') {
      		steps {
        		withKubeConfig([credentialsId: 'kubeconfig']) {
          			sh 'bash zap.sh'
        		}
      		}
    	}
	}
  	post {
  		always {
    		junit 'target/surefire-reports/*.xml'
      		jacoco execPattern: 'target/jacoco.exec'
      		publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML Report', reportTitles: 'OWASP ZAP HTML Report', useWrapperFileDirectly: true])
    	}
	    // success {
	
	    // }
	
	    // failure {
	
	    // }
	} 
}