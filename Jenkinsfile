def label = "jenkins-slave-${UUID.randomUUID().toString()}"
podTemplate(
    label: label,
    containers: [
        containerTemplate(name: 'maven', image: 'maven:3.8.1-jdk-8', ttyEnabled: true, command: 'cat', privileged: false),
        containerTemplate(name: 'kubectl', image: 'lachlanevenson/k8s-kubectl:v1.18.17', command: 'cat', ttyEnabled: true, privileged: false),
        containerTemplate(name: 'buildctl',image:'shopstic/buildctl:0.8.3-2',command: 'cat' , ttyEnabled: true, privileged: false)
    ],
    namespace: 'jenkins',
    serviceAccount: 'jenkins',
    volumes: [
        hostPathVolume(hostPath: '/appdata/jenkins_data_k8s/localrepository',mountPath: '/root/.m2'),
        hostPathVolume(hostPath: '/appdata/jar',mountPath:'/mnt')
    ],
    workspaceVolume: hostPathWorkspaceVolume('/appdata/jenkins_data_k8s')
){
    node(label) {
        stage('Get a maven project') {
            git credentialsId: 'new',url: 'https://github.com/zww0019/JrebelLicenseServerforJava.git'
            script {
                        env.container_name='jlsl'
                        env.image_tag = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                        env.repo_name = 'registry.kdphoto.cn'
                        env.app_name = 'jlsl'
                    }
            container('maven') {
                stage('打包') {
                    sh 'mvn clean install -f pom.xml -Dmaven.test.skip=true'
                }
            }
        }
        stage('Build a image'){
            container('buildctl'){
                stage('构建镜像'){
                    sh 'buildctl \
                          --addr tcp://buildkitd:1234 \
                          build --frontend dockerfile.v0 --local context=. --local dockerfile=. --opt filename=./Dockerfile  \
                          --output type=image,name=${repo_name}/${app_name}:${image_tag},push=true'
                }
            }
        }
        stage('Run pod'){
            container('kubectl'){
                stage('run'){
                    sh "sed -i 's/repo_placeholder/${repo_name}/' deployment/${app_name}.yml"
                    sh "sed -i 's/app_placeholder/${app_name}/' deployment/${app_name}.yml"
                    sh "sed -i 's/tag_placeholder/${image_tag}/' deployment/${app_name}.yml"

                    sh 'kubectl apply -f deployment/${app_name}.yml'
                }
                stage('verification'){
                    sh 'kubectl rollout status -n default deployment ${app_name}'
                }
            }
        }
    }
}