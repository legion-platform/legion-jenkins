def deployJenkins() {
    withCredentials([
    file(credentialsId: "vault-jenkins", variable: 'vault')]) {
        withAWS(credentials: 'kops') {
            wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
                docker.image("${env.param_docker_repo}/k8s-jenkins-ansible:${env.param_legion_jenkins_version}").inside("-e HOME=/opt/legion/ -u root") {
                    stage('Deploy Jenkins') {
                        sh """
                        cd ${ansibleHome} && \
                        ansible-playbook deploy.yml \
                        ${ansibleVerbose} \
                        --vault-password-file=${vault} \
                        --extra-vars "param_env_name=${param_env_name} \
                        legion_jenkins_version=${env.param_legion_jenkins_version} \
                        legion_version=${env.param_legion_version} \
                        pypi_repo=${env.param_pypi_repo} \
                        helm_repo=${env.param_helm_repo} \
                        docker_repo=${env.param_docker_repo}"
                        """
                    }
                }
            }
        }
    }
}

def undeployJenkins() {
    withCredentials([
    file(credentialsId: "vault-jenkins", variable: 'vault')]) {
        withAWS(credentials: 'kops') {
            wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
                docker.image("${env.param_docker_repo}/k8s-jenkins-ansible:${env.param_legion_jenkins_version}").inside("-e HOME=/opt/legion/ -u root") {
                    stage('Undeploy Jenkins') {
                        sh """
                        cd ${ansibleHome} && \
                        ansible-playbook undeploy.yml \
                        ${ansibleVerbose} \
                        --vault-password-file=${vault} \
                        --extra-vars "param_env_name=${param_env_name} \
                        legion_jenkins_version=${env.param_legion_jenkins_version}  \
                        helm_repo=${env.param_helm_repo} \
                        docker_repo=${env.param_docker_repo}"
                        """
                    }
                }
            }
        }
    }
}


def runRobotTests() {
    withCredentials([
    file(credentialsId: "vault-${env.param_profile}", variable: 'vault')]) {
        withAWS(credentials: 'kops') {
            wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
                docker.image("${env.param_docker_repo}/jenkins-pipeline-agent:${env.param_legion_jenkins_version}").inside("-e HOME=/opt/legion -u root") {
                    stage('Run Robot tests') {
                        dir("${WORKSPACE}"){
                            def nose_report = 0
                            def robot_report = 0
                            sh "./tests/run_robot_tests.sh ${env.param_profile} ${env.param_legion_jenkins_version}"

                            robot_report = sh(script: 'find tests/ -name "*.xml" | wc -l', returnStdout: true)

                            if (robot_report.toInteger() > 0) {
                                step([
                                    $class : 'RobotPublisher',
                                    outputPath : 'tests/',
                                    outputFileName : "*.xml",
                                    disableArchiveOutput : false,
                                    passThreshold : 100,
                                    unstableThreshold: 95.0,
                                    onlyCritical : true,
                                    otherFiles : "*.png",
                                ])
                            }
                            else {
                                echo "No '*.xml' files for generating robot report"
                                currentBuild.result = 'UNSTABLE'
                            }

                        }
                    }
                }
            }
        }
    }
}

return this
