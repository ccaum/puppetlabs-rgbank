node {

  //git url: 'git@github.com:puppetlabs/puppetlabs-rgbank.git', credentialsId: 'rgbank-module-deploy-key'
  git url: 'https://github.com/puppetlabs/puppetlabs-rgbank'

  stage('Lint and unit tests') {
    withEnv(['PATH=/usr/local/bin:$PATH']) {
      sh '''
        bundle install
        bundle exec rspec spec/
      '''
    }
  }

  stage('Beaker Acceptance Test') {
    withCredentials([
        string(credentialsId: 'OS_AUTH_URL', variable: 'OS_AUTH_URL'),
        string(credentialsId: 'OS_KEYNAME', variable: 'OS_KEYNAME'),
        string(credentialsId: 'OS_NETWORK', variable: 'OS_NETWORK'),
        string(credentialsId: 'OS_PASSWORD', variable: 'OS_PASSWORD'),
        string(credentialsId: 'OS_TENANT_NAME', variable: 'OS_TENANT_NAME'),
        string(credentialsId: 'OS_USERNAME', variable: 'OS_USERNAME')
    ]) {
      withEnv(['PATH=/usr/local/bin:$PATH']) {
        ansiColor('xterm') {
          sh '''
            bundle install
            export OS_VOL_SUPPORT=false
            bundle exec rake beaker:centos7-openstack
            '''
        }
      }
    }
  }

  stage('Set Tag Data'){
    sshagent(['control-repo-github']) {
      sh '''
        git tag $BUILD_TAG
        git push --tags
        '''
    }

    stage('Deploy Latest Version'){
      build job: 'control-repo', parameters: [
        [$class: 'StringParameterValue',name: 'TAG',value: env.BUILD_TAG],
        [$class: 'StringParameterValue',name: 'MODULE',value: 'rgbank'],
        [$class: 'StringParameterValue',name: 'PARAM', value: ':ref']
      ]
    }
  }
}
