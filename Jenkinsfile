@Library('slack') _

/////// ******************************* Code for fectching Failed Stage Name ******************************* ///////
import io.jenkins.blueocean.rest.impl.pipeline.PipelineNodeGraphVisitor
import io.jenkins.blueocean.rest.impl.pipeline.FlowNodeWrapper
import org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper
import org.jenkinsci.plugins.workflow.actions.ErrorAction


// Get information about all stages, including the failure cases
// Returns a list of maps: [[id, failedStageName, result, errors]]
@NonCPS
List < Map > getStageResults(RunWrapper build) {

  // Get all pipeline nodes that represent stages
  def visitor = new PipelineNodeGraphVisitor(build.rawBuild)
  def stages = visitor.pipelineNodes.findAll {
    it.type == FlowNodeWrapper.NodeType.STAGE
  }

  return stages.collect {
    stage ->

      // Get all the errors from the stage
      def errorActions = stage.getPipelineActions(ErrorAction)
    def errors = errorActions?.collect {
      it.error
    }.unique()

    return [
      id: stage.id,
      failedStageName: stage.displayName,
      result: "${stage.status.result}",
      errors: errors
    ]
  }
}

// Get information of all failed stages
@NonCPS
List < Map > getFailedStages(RunWrapper build) {
  return getStageResults(build).findAll {
    it.result == 'FAILURE'
  }
}

pipeline {
	agent { label 'maven' }
	environment {
		deploymentName = "devsecops"
		namespaceName = "devsecops"
	    containerName = "devsecops-container"
	    serviceName = "devsecops-svc"
	    imageName = "mampudia/numeric-app:${GIT_COMMIT}"
	    applicationURL = "https://udemy-devsecops.ampudiacompany.com/numeric"
	    applicationURLProd = "http://192.168.1.54"
	    applicationURI = "/increment/99"
	}
	stages {
	  	stage ('Parameters') {
	        steps {
	            echo '---Parameters GIT HUB'
	            echo "BRANCH_NAME: ${env.GIT_BRANCH.split("/")[1]}"
	            sh "pwdd"
	        }
	    }
	    stage('Testing Slack - Error Stage') {
	    	steps {
	        	sh 'exit 0'
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
			agent { 
	      		label 'builnode'
	      	}
      		steps {
        		withKubeConfig([credentialsId: 'kubeconfig']) {
          			sh 'bash zap.sh'
        		}
      		}
      		post {
      			always {
      				publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML Report', reportTitles: 'OWASP ZAP HTML Report', useWrapperFileDirectly: true])
      			}
      		}
    	}
    	stage('Prompte to PROD?') {
			steps {
				timeout(time: 2, unit: 'DAYS') {
			    	input message: 'Do you want to Approve the Deployment to Production Environment/Namespace?', submitter: 'dev'
				}
			}
		}
		stage('K8S CIS Benchmark') {
			agent { 
	      		label 'builnode'
	      	}
	     	steps {
	     		withKubeConfig([credentialsId: 'kubeconfig']) {
	     			script {
		          		parallel(
		            		"Master": {
		              			sh "bash cis-master.sh"
		            		},
		            		"Etcd": {
		              			sh "bash cis-etcd.sh"
		            		},
		            		"Kubelet": {
		              			sh "bash cis-kubelet.sh"
		            		}
		          		)
	        		}
	     		}
	      	}
	    }
	    stage('K8S Deployment - PROD') {
	    	steps {
	        	parallel(
		          	"Deployment": {
		            	withKubeConfig([credentialsId: 'kubeconfig']) {
		              		sh "sed -i 's#replace#${imageName}#g' k8s_PROD-deployment_service.yaml"
		              		sh "kubectl -n prod apply -f k8s_PROD-deployment_service.yaml"
		            	}
		          	},
		          	"Rollout Status": {
		            	withKubeConfig([credentialsId: 'kubeconfig']) {
		              		sh "bash k8s-PROD-deployment-rollout-status.sh"
		            	}
		          	}
	        	)
	    	}
	    }
	    stage('Integration Tests - PROD') {
			steps {
		      	script {
		        	try {
		            	withKubeConfig([credentialsId: 'kubeconfig']) {
		              		sh "bash integration-test-PROD.sh"
		            	}
		          	} catch (e) {
		            	withKubeConfig([credentialsId: 'kubeconfig']) {
		              		sh "kubectl -n prod rollout undo deploy ${deploymentName}"
		            	}
		            	throw e
		        	}
		    	}
			}
		}
	}
  	post {
  		//always {
    		// Use sendNotifications.groovy from shared library and provide current build result as parameter    
      		//sendNotification currentBuild.result
    	//}
	    success {
			 script {
		        /* Use slackNotifier.groovy from shared library and provide current build result as parameter */
		     	env.failedStage = "none"
		        env.emoji = ":white_check_mark: :tada: :thumbsup_all:"
		        sendNotification currentBuild.result
		      }
	    }
	    failure {
	    	script {
	        	//Fetch information about  failed stage
	        	def failedStages = getFailedStages(currentBuild)
	        	env.failedStage = failedStages.failedStageName
	        	env.emoji = ":x: :red_circle: :sos:"
	        	sendNotification currentBuild.result
	     	}
	    }
	} 
}