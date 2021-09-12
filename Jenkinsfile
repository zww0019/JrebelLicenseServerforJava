def app_name='jlsl'
def deployment_name='jlsl'
def deployment_file='deployment-14.yml'
def img_tag="${UUID.randomUUID().toString().substring(0,5)}"
podTemplate(
	inheritFrom: 'kubernetes',
	containers: [
	    containerTemplate(name: 'maven', image: 'maven:3.8-openjdk-8', ttyEnabled: true, command: 'cat', privileged: false)
	],
    label: 'commonbuild',
    name: 'commonbuild'
){
	node('commonbuild') {
        stage('Get a maven project') {
            git credentialsId: 'zww',url: 'https://github.com/zww0019/JrebelLicenseServerforJava.git'
            container('maven') {
                stage('打包') {
                    sh 'mvn clean install -f pom.xml -Dmaven.test.skip=true'
                }
            }
        }
    }
}
podTemplate(
    label: 'buildimage',
    inheritFrom: 'kubernetes',
	containers: [
	    containerTemplate(name: 'buildctl',image:'shopstic/buildctl:0.9.0',command: 'cat' , ttyEnabled: true, privileged: false)
	],
	envVars: [
	    envVar(key: 'app_name',value: app_name),
	    envVar(key: 'image_tag',value: img_tag)
	],
	nodeSelector: 'kubernetes.io/arch=amd64'

){
	node('buildimage') {
        stage('Build a Image') {
            container('buildctl'){
                stage('构建镜像'){
                    sh 'buildctl \
                          --addr tcp://buildkitd:1234 \
                          build --frontend dockerfile.v0 --local context=. --local dockerfile=. --opt filename=./Dockerfile  \
                          --output type=image,name=${repo_name}/${app_name}:${image_tag},push=true'
                }
            }
        }
    }
}
podTemplate(
    label: 'deploymentpod',
    inheritFrom: 'kubernetes',
	containers: [
	    containerTemplate(name: 'kubectl', image: 'lachlanevenson/k8s-kubectl:v1.18.20', command: 'cat', ttyEnabled: true, privileged: false)
	],
	envVars: [
	    envVar(key: 'app_name',value: app_name),
	    envVar(key: 'deployment_file',value: deployment_file),
	    envVar(key: 'deployment_name',value: deployment_name),
	    envVar(key: 'image_tag',value: img_tag)
	],
	volumes: [
            persistentVolumeClaim(claimName: 'pvc-nfs-other-provisioner-nfs-subdir-external-provisioner',mountPath: '/opt'),
        ],
	nodeSelector: 'node-role.kubernetes.io/master=true'
){
	node('deploymentpod') {
        stage('Deploy') {
            container('kubectl'){
                stage('run'){
                    // 复制deployment文件到当前目录
                    sh "cp /opt/k8s/${deployment_file} ./"

                    sh "sed -i 's/repo_placeholder/${repo_name}/' ${deployment_file}"
                    sh "sed -i 's/app_placeholder/${app_name}/' ${deployment_file}"
                    sh "sed -i 's/tag_placeholder/${image_tag}/' ${deployment_file}"
                    sh "cat ${deployment_file}"
                    sh 'kubectl apply -f ${deployment_file}'
                }
                stage('verification'){
                    sh 'kubectl rollout status -n default deployment ${deployment_name}'
                }
            }
        }
    }
}
