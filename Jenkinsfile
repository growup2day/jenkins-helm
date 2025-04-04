podTemplate(
  containers: [
    containerTemplate(
      name: 'jnlp',
      image: 'docker-ose-platform-local.artifactory-staging.nz.service.anz/jenkins-ocp-anz/ose-jenkins-agent-maven:20230623',
      command: "/usr/local/bin/run-jnlp-client",
      args: '-webSocket ${computer.jnlpmac} ${computer.name}',
      resourceRequestCpu: '200m',
      resourceLimitCpu: '500m',
      resourceRequestMemory: '200Mi',
      resourceLimitMemory: '500Mi',
      ),
    containerTemplate(
      name: 'helm-test',
      image: 'docker-digital-image-builds-local.artifactory.nz.service.anz/helm-unittest/helm-unittest:3.7.1-0.2.8',
      alwaysPullImage: true,
      command: 'cat',
      ttyEnabled: true,
      resourceRequestCpu: '200m',
      resourceLimitCpu: '1000m',
      resourceRequestMemory: '500Mi',
      resourceLimitMemory: '1Gi',
      )
  ],
  nodeUsageMode: 'EXCLUSIVE',
  nodeSelector: 'beta.kubernetes.io/os=linux'
) {
  node(POD_LABEL) {
    stage('checkout') {
      deleteDir()
      checkout scm
    }
    stage('test') {
      container('helm-test') {
        sh './test.sh'
      }
    }
  }
}
