#!groovy

import groovy.json.JsonOutput
import java.util.Optional
import hudson.tasks.test.AbstractTestResultAction
import hudson.model.Actionable
import hudson.tasks.junit.CaseResult

// Agents labels
def linuxAgent = 'master'
def winagent   = 'DALLAS-Win-201'
def agentLabel = 'ZOS-REMOTE-AGENT'
def s390xLable = 's390x'

//GitHub Details
def gitRepo = 's390x-r'

// 
def gitOrg = 's390x-images'
def gitHost = 'github.ibm.com'
def gitCredId = 'ibm_github_cred_notify'
def srcGitRepo =   'git@' + gitHost + ':' + gitOrg + '/' + gitRepo
def srcGitBranch = 'master'
def scmVars = ''
def GITHUB_API_URL = 'https://github.ibm.com/api/v3/repos/'+ gitOrg + '/' + gitRepo

// options { skipDefaultCheckout(true) }

pipeline {
    agent { label s390xLable }
    environment {
        def app =''

    }
stages {

    //   stage('Init Clean') {
    //     /* Cloning the Repository to our Workspace */
    // steps {
    //         script {
    //             node( s390xLable ){
    //                 sh '''docker container kill $(docker ps -q)'''
    //                 sh '''docker container rm $(docker ps -a -q)'''
    //                 sh '''docker image rm $(docker images -a -q)'''
    //                 }
    //             }
    //         }
    //     }


      stage('Clone repository') {
        /* Cloning the Repository to our Workspace */
    steps {
            script {
                node( s390xLable ){
                    scmVars = checkout scm
                    env.GIT_COMMIT = scmVars.GIT_COMMIT
                    }
                }
            }
        }

    stage('Build image') {
     steps {
            script {
                node( s390xLable ){
                    /* This builds the actual image */
                    // sh 'source ../.bashrc'
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-hub') {
                        app = docker.build("ashish1981/'$gitRepo'")
                        }
                    }
                }
            }
        }

    // stage('Test image') {
    //     steps {
    //         script {  
    //             node( s390xLable ){
    //                 app.inside {
    //                     logstash -V
    //                     echo "Tests passed"
    //                     }
    //                 }
    //             }
    //         }
    //     }

    // stage('Push image') {
    //    steps {
    //        script {
    //            node( s390xLable ){
    //             /* 
    //                 You would need to first register with DockerHub before you can push images to your account
    //             */
    //                 docker.withRegistry('https://registry.hub.docker.com', 'docker-hub') {
    //                         app.push("${env.BUILD_NUMBER}")
    //                         app.push("latest")
    //                         } 
    //                 echo "Trying to Push Docker Build to DockerHub"
    //                 }    
    //             }       
    //         }
    //     }

    // stage('Clean Images') {
    //     /* Cleaning the Repository to our Workspace */
    //     steps {
    //         script {
    //             node( s390xLable ){
    //                 // sh '''docker container kill $(docker ps -q)'''
    //                 // sh '''docker container rm $(docker ps -a -q)'''
    //                 sh '''docker image rm -f $(docker images -a -q)'''
    //                 }
    //             }
    //         }
    //     }

    
    
    
    
    }
    post {

            success {
                script{

                        withCredentials([usernamePassword(credentialsId: 'ibm_github_cred_notify', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')])
                        {
                            sh "curl -s --user \"$USERNAME:$PASSWORD\" -X POST -d '{\"state\": \"success\"}' \"$GITHUB_API_URL/statuses/$GIT_COMMIT\""
                        }
                    }
                }
            unstable {
                script{

                        withCredentials([usernamePassword(credentialsId: 'ibm_github_cred_notify', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')])
                        {
                            sh "curl -s --user \"$USERNAME:$PASSWORD\" -X POST -d '{\"state\": \"pending\"}' \"$GITHUB_API_URL/statuses/$GIT_COMMIT\""
                        }
                    }
                }
            failure {
                script{

                        withCredentials([usernamePassword(credentialsId: 'ibm_github_cred_notify', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')])
                        {
                            sh "curl -s --user \"$USERNAME:$PASSWORD\" -X POST -d '{\"state\": \"failure\"}' \"$GITHUB_API_URL/statuses/$GIT_COMMIT\""
                        }
                    }
                }
            aborted {
                script{

                        withCredentials([usernamePassword(credentialsId: 'ibm_github_cred_notify', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')])
                        {
                            sh "curl -s --user \"$USERNAME:$PASSWORD\" -X POST -d '{\"state\": \"error\"}' \"$GITHUB_API_URL/statuses/$GIT_COMMIT\""
                        }
                    }
                }
        }

}
