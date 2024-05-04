# TimeOff Morningstar


A sample environment to run a TimeOff application 

This project uses the following tools:

- [Kubernetes](#Kubernetes)
- [Jenkins](#Jenkins)
- [Terraform](#Terraform)


### Content
- [Introduction](#Introduction)
  - [Kubernetes](#Kubernetes)
  - [Jenkins](#Jenkins)
  - [Terraform](#Terraform)
- [Functionality](#Functionality)
- [Configuration](#Configuration)
  - [Step 1: Deploying a containerized cluster on AWS](#Step-1-Deploying-a-containerized-cluster-on-AWS)
  - [Step 2: Setting up Jenkins pipelines](#Step-2-Setting-up-Jenkins-pipelines)
  - [Step 3: Deploying TimeOff application](#Step-3-Deploying-TimeOff-application)
- [Considerations](#Considerations)
  - [Future Improvements](#Future-Improvements)
  - [Problems I faced](#Problems-I-faced)




## Introduction


TimeOff.Management is an online employees absence management app. It supports many useful features such as Multiple views of staff absences, absence types, Third Party Calendar Integration and Three Steps Workflow.
This project aims at deploying the TimeOff application containerzied on AWS, all using terraform while supporting automated builds for future updates and bug fixes.




### Kubernetes

Kubernetes, also known as K8s, is an open-source system for automating deployment, scaling, and management of containerized applications.
Kubernetes groups containers that make up an application into logical units for easy management and discovery. Kubernetes builds upon 15 years of experience of running production workloads at Google, combined with best-of-breed ideas and practices from the community.




### Jenkins

Jenkins is an open-source automation tool written in Java with plugins built for continuous integration. Jenkins is used to build and test software projects continuously making it easier for developers to integrate changes to the project, and making it easier for users to obtain a fresh build. It also allows you to continuously deliver your software by integrating with a large number of testing and deployment technologies.


### Terraform

Terraform is an infrastructure as code tool that lets you define both cloud and on-prem resources in human-readable configuration files that you can version, reuse, and share. You can then use a consistent workflow to provision and manage all of your infrastructure throughout its lifecycle. Terraform can manage low-level components like compute, storage, and networking resources, as well as high-level components like DNS entries and SaaS features.




## Functionality

<p align="center">
  <img width="700" height="400" src="https://raw.githubusercontent.com/zedahmed144/Morningstar/master/solution-diagram.png?raw=true">
</p>

A CICD pipeline is setup to continiously integrate and deploy changes made to the code. A push to the GitHub repo will send a payload to jenkins which will trigger a new build of our application, as well as deploying that to our infrastructure.

### Step 1: Deploying a containerized cluster on AWS

The assignment requires the application to run a containers (ECS or EKS). Since EKS is not a free service, i opted for a regular Kubernetes cluster deployed on AWS EC2s using <code>Kubeadm</code>. 
I created and attached a fully functioning EKS cluster using terraform that can be found in the repo. It leverages EKS managed nodes group to make use of AWS spot instances to cut costs. But for this demo, i opted for a kubeadm cluster.


### Step 2: Setting up Jenkins pipelines

I created and attached a Jenkins pipeline with 3 users <code>(Build, Read, Admin)</code> and configure a job to run and scan the repo. Jenkins image has all the necessary pluging and configs needed to run the timeOff app smoothly. Jenkins leverage service account to get access to ECR to push and pull images. This is managed by AWS IAM policies. 
However, because - as mentionned above - we are not using EKS, this Jenkins IaC cannot be used until we deploy our EKS cluster (which is not free). For this demo, i manually setup Jenkins pipelines and builds. 
The attached jenkins code leverages <code>JCASC (Jenkins Configuration As A Code)</code>. 
Jenkins is a very powerful tool, anyone who accuires access, can run any jobs on our infrastructre. Because of that. We deployed Jenkins as a StatefulSet and used Matrix based authentication. Only Authenticated users can access Jenkins. We also used external, encrypted AWS EBS storage for our configurations.

### Step 3: Deploying TimeOff application

Whenever there's a push to GitHub, a payload will be send to Jenkins Master and trigger it. Jenkins master will create a jenkins agend pod that will do all the work. The worker pod will clone the repo and read the Jenkinsfile for instructions on how to run the job. The Jenkinsfile uses a Makefile with targets to:

<code>1. Build</code> image using the provided docker file.
<code>2. Login</code> to AWS ECR.
<code>3. Push</code> Image to AWS ECR.
<code>4. Deploy</code> the application using a provided manifest in the repo.

An ingress file is also provided. However, since there's no hostname provided to use to resolve to our kubernetes services., we will be using NodePorts to access our app. 

To access the apps, we will use:

<code>http://morningstar-eb36af985ddc7e69.elb.us-east-1.amazonaws.com:80</code>: To access TimeOff App.
<code>http://morningstar-eb36af985ddc7e69.elb.us-east-1.amazonaws.com:81</code>: To access Jenkins Master UI.

## Considerations

### Future Improvements

1. Jenkins cannot be Internet Facing.
2. Use Ingress to resolve to services instead of NodePort.
3. Use AWS EKS as it is guranteed by AWS.
4. Use external storage for the TimeOff app (currently using SQLite database within the app itself).
5. Have multiple stages to test the image before deploying.
6. Migrate from an Alpine base image for TimeOff app, to a NodeJs base image to reduce dependecies and size.
7. Run TimeOff as a statefulSet for high consistency.
8. More security practices can be implemented (WAF, Encrypted DB, Network Policy, Service Accounts ..).
9. All the above project, inclusing the Timeoff app, EKS, and Jenkins itself. can be deployed automatically through a 3rd Jenkins pipeline.

### Problems I faced

1. Lots of incompatible dependencies.
2. Outdated Dependencies.
3. Base image needs much plugins, which increased the size of the Timeoff image.
4. JCASC: Configuring Jenkins through code tends to be VERY complex.
5. A manual Kubernetes cluster can be laggy sometimes.
