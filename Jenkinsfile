podTemplate(yaml: """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: some-label-value
spec:
  containers:
  - name: jenkins-slave
    image: mshaibek/jenkins-slave-312
    command:
    - cat
    tty: true
    env:
    - name: DOCKER_HOST
      value: 'tcp://localhost:2375'
  - name: dind-daemon
    image: 'docker:18-dind'
    command:
    - dockerd-entrypoint.sh
    tty: true
    securityContext: 
      privileged: true 
"""
) {
    properties([
      pipelineTriggers([
        // build job if there was a github pushh
        [$class: 'GitHubPushTrigger'],
        // pollSCM('*/1 * * * *'), // poll every 1 minute
        ])
    ])
    node(POD_LABEL) {
      checkout scm
      container('jenkins-slave') {
        sh ''' 
        export AWS_DEFAULT_REGION=us-east-1
        set -xe
        kubectl apply -f demo.yaml
        '''
      }
    }
}
