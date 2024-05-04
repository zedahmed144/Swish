
# Jenkins Master in EKS cluster

## What is Jenkins and why do we use it?
Automation, including CI/CD and test automation, is one of the key practices that allow DevOps teams to deliver “faster, better, cheaper” technology solutions. [Jenkins](https://www.jenkins.io/doc/) is the most popular open source CI/CD tool on the market today and is used in support of DevOps, alongside other cloud native tools. Jenkins is used to build and test your product continuously, so developers can continuously integrate changes into the build. 

You can read more about jenkins features and use cases [here](https://www.spiceworks.com/tech/devops/articles/what-is-jenkins/#:~:text=Jenkins%20is%20a%20Java%2Dbased,to%20get%20a%20new%20build.).


## Goals
1. Create [Jenkins server in k8s](https://www.jenkins.io/doc/book/installing/kubernetes/)
2. Be able to apply configurations dynamically, with no manual intervention
3. Inject secrets used by jenkins using k8s best practices. 

## Overview 
We are setting up Jenkins master in EKS cluster, using custom image which is stored in ECR, with dynamic setup for cloud, user and job configurations.  Jenkins secrets such as users & credentials, github repo and access tokens are stored in AWS Secret Manager which will be injected into jenkins-master pod via k8s secrets. We use IAM roles and policies to be able to access above mentioned AWS resources. Finally, in route53 we create a record for jenkins.centos22b.exchangeweb.net to access jenkins. 
<p align="center">
<img width="836" alt="image" src="https://user-images.githubusercontent.com/64542132/204175168-05faab09-4456-4b9f-bafd-97bacb34c754.png"/p>


### Pre-requisites
You need to have the following in your environment to run this locally or create your own: 
- [Docker](https://docs.docker.com/get-docker/) installed on your machine
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) command line tool 
- [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured to access your cluster and other AWS resources as required

## How to run current setup on your local?

1. Clone this repo to your local
2. Follow commands below:
```
cd Kubernetes/jenkins/jenkins-master/

make all

```
OR

```
make [target] [variable]=[value]  - depending on the target, make sure to check existing values in Makefile for aws region, acctID, version etc and provide values as in example below

make build version=1.1 

```

## STEP 1: How to create your own? Start with creating custom jenkins image

<p align="center">
<img width="654" alt="image" src="https://user-images.githubusercontent.com/64542132/204170652-82069e68-c7ee-4ae1-88de-1745a3921a9a.png"/p>



1. `FROM --platform=linux/amd64 jenkins/jenkins:latest`  - we use official [jenkins/jenkins:latest](https://hub.docker.com/r/jenkins/jenkins) from dockerhub as our base image. Also, while building an image, Docker engine automatically chooses OS/CPU architecture based on your current one. For ex, if you run `docker buld -t image:version` on a MacOS machine, your image is compatible to run on linux/arm64. To be able to run our image in Amazon Linux machine, we specify architecture as `--platform=linux/amd64`. For more info, refer [here](https://docs.docker.com/engine/reference/builder/#from:~:text=.%20is%20ignored.-,FROM,-%F0%9F%94%97)

2. `COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt` -  Jenkins itself can't do much without plugins installed, we created a _plugins.txt_  in our `docker/` folder and copy it to container, change owner so jenkins will have all required permissions to use this file later. 

3. `COPY --chown=jenkins:jenkins configs/ configs/` - inside _docker/config/_ we have user configuration files, cloud configuration, job configuration and secret keys used by jenkins to encrypt sensitive data. All configuration files are in XML format.

4. `COPY --chown=jenkins:jenkins initial-setup.sh /bin/ ` in _docker_ folder, we created _initial setup.sh_ script, we add this file to container, put it in_ /bin_ folder and later execute it as an ENTRYPOINT. 

5. `RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt` - jenkins has it's own utility tool _jenkins-plugin-cli_. In this line we run this command and provide file with plugins. This will install plugins listed in the file. 

6. `ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false" ` - this will ensure that after jenkins is ready, it skips the launch page. 

7. `USER root` - self descriptive, run as a root user

8. `ENTRYPOINT [ "/usr/bin/tini", "--", "/bin/initial-setup.sh"]`  - by default Jenkins runs _jenkins.sh_ as it's entrypoint. Here we are overriding it with our own scipt that will replace all variables in configuration files with valid data. 


Run `docker build -t IMAGE_NAME:VERSION ` to create image. 
Then push it to the docker registry of your choice, here we use ECR. 


## STEP 2: Injecting AWS secrets to the pod via k8s secrets.

1. Create secrets in AWS Secret Manager. 
Go to AWS Console > AWS Secret Manager > Create Secret > Select type _Other_ > Name your secret > provide value as _Plaintext_  > Save.
Here's the example:
<p align="center">
<img width="1151" alt="image" src="https://user-images.githubusercontent.com/64542132/204339265-d43e6867-c6b5-4bd1-a973-0dec43bb09e5.png"/p>

Kubernetes doesn't have it's own utilities to retrieve secret from AWS and provide it to the pod. To accomplish this, _secret-store-csi-driver_ and _aws-secret-provider-installer_ are used in this project. Basically, together they enable us to retrieve secrets from AWS and create k8s Secret object. 
  
2. Create IAM role to give your jenkins pod an access to your AWS Secrets.

    a. Create IAM OIDC Provider for EKS ( it's one per cluster, so if it already exists you can use that)

    b. Create IAM Policy to Read Secrets

    c. Create IAM Role for a Kubernetes Service Account (serviceAccount should be the one used by jenkins)
  
    d. Associate an IAM Role with Kubernetes Service Account
  


3. Then, provide it to the pod as ENV variable, these ENV values are used in `/bin/initial-setup.sh` we mentioned above, to replace variables with valid data. 
<p align="center">
<img width="659" alt="image" src="https://user-images.githubusercontent.com/64542132/204174684-7132cf11-6a9a-401f-b4a7-7032ce3d0b22.png"
/p>

4. Run `kubectl get po -n kube-system`  to see if your cluster has csi-driver running. If you see the pods highlighted in the image above, you have csi-driver and no installation is required. These run as daemons on each node. 
If you don't have it installed, you can use links in resources section

<p align="center">
<img width="585" alt="image" src="https://user-images.githubusercontent.com/64542132/204177127-dc0bc900-2d72-41b4-a503-0127bd7e9699.png"
/p>

5. After you have installed csi-driver, create `SecretProviderClass`, it looks something like this (full file can be found in jenkins.yaml).
Refer to this [article](https://blog.spikeseed.cloud/handling-aws-secrets-and-parameters-on-eks/) for more info. 

<p align="center">
<img width="817" alt="image" src="https://user-images.githubusercontent.com/64542132/204174505-06ae97bd-bb84-427f-9f68-bab2f52502b2.png"
/p>


## STEP 3: Deploy Jenkins in Kubernetes

Now, when our image is ready, we have our secrets created, configured a way to inject them into pods we create all jenkins resources in it's own namespace, to isolate it from other applications running in the same cluster
In `jenkins.yaml` manifesto you'll find all the jenkins resources definitions. 

1. Run `make [target] or make all` and you should see the following resources created as a result:

<p align="center">
<img width="619" alt="image" src="https://user-images.githubusercontent.com/64542132/204178144-1c058bf8-157b-4b48-8290-8ec5df2f4046.png"
/p>
  
  
## STEP 4: Access jenkins and run pipeline
  
1. Go to `http://jenkins.22bcentos.exchangeweb.net/` in your browser to access jenkins and login with valid credentials. 
  
2. Find the repository/branch you would like to scan and click on 'Build Now'

  
## What is organization scan?

The GitHub Branch Source plugin implements the feature of `Scan Organization`, which basically scans a whole organization for GitHub repositories and their branches and updates them in Jenkins. 

Once you login, you will see only one job setup, named 22b-centos-org. 
Current job configuration uses org scan. It scans all the repositories and their branches present in github org, [312-bc](https://github.com/orgs/312-bc/repositories). If it finds _Jenkinsfile_ it will run the pipeline. 
By default, It scans all 90+ repositories in 312-bc and that is not what we need. To avoid this, we are using filter **Filter by name (with regular expression)** with **.*-22b-centos** expression. As a result, it will scan only the matching ones and ignore the rest

<p align="center">
<img width="1149" alt="image" src="https://user-images.githubusercontent.com/64542132/204180752-9587fe49-fedd-4f94-928a-7a70c4129b22.png"
/p>

## Configuring your Jenkinsfile to run with current jenkins

_jenkins-slave_ docker image and _jenkins-slave.yaml_ are not provided as part of this task. [This](https://github.com/312-bc/cicd-demo-22b/blob/master/Jenkinsfile) should work fine for you as an example. 


1. Create Jenkinsfile according to your app requirements. 
2. Create _jenkins-slave.yaml_. While providing jenkins-slave.yaml, make sure you have added `jenkins-sa` serviceAccount under `spec.serviceAccount`
<p align="center">
<img width="355" alt="image" src="https://user-images.githubusercontent.com/64542132/204181603-16dd762c-cda2-4f88-aa9c-728752ba2261.png"
/p>


_Note_: _If you don't specify serviceAccount, the slave pod will use default serviceAccount which doesn't have required permissions._ 



3. Once your Jenkinsfile is ready, push your project to remote and trigger the build manually in UI. 


## Opportunities 

These are additional automation opportunities worth exploring:

1. Use [CaSC](https://www.jenkins.io/doc/book/managing/casc/) plugin in jenkins, to configure it via human readable _yaml_ files, instead of XML. 

2. Use `terraform` for creating secrets, policies, roles, policy attachments in AWS.

3. Use `github-webhooks` to automate pipeline runs in jenkins at every push to Github. 
  



# Resources
Jenkins in k8s - https://www.jenkins.io/doc/book/installing/kubernetes/

How to write user-setup.groovy - https://gist.github.com/wiz4host/17ab33e96f53d8e30389827fbf79852e

Pre-installing plugins - https://github.com/jenkinsci/docker/#preinstalling-plugins

How to use aws-secrets-provider with csi-driver - https://aws.amazon.com/blogs/security/how-to-use-aws-secrets-configuration-provider-with-kubernetes-secrets-store-csi-driver/

How to setup csi-driver step-by-step - https://www.youtube.com/watch?v=Rmgo6vCytsg&t=364s
  
Configure service account for pods - https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
