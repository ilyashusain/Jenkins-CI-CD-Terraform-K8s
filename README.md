# Jenkins CI/CD Terraform K8s

# Outline of Solution

**Brief:**

In this guide we will be using Jenkins to attain full CI/CD integration for our pipeline for a sample webpage app, using Terraform and Kubernetes (k8s) to manage our infrastructure and containers respectively.

We will perform this on a CentOS-7 machine that will be acting as our master node, and for this node we recommend at least 1 vCPU (jenkins tends to crash on smaller machines). Our cloud provider of choice will be Google Cloud Platform; for this guide we assume basic knowledge of GCP, this includes how to create service accounts.

**Outline:**

We will first create a master node. On our master node we will install Terraform to help spin up a cluster of nodes. We will then download ```kubectl``` (Kubernetes functionality) and fetch the credentials for our cluster which will allow us to interact with the cluster using ```kubectl``` commands. Next, we will containerize a web application using Docker and deploy this containerized application on to one of the cluster nodes by again using ```kubectl``` commands.

Also, on our master node is a jenkins controller that waits for commit requests from Github. On each commit, the deployment on the cluster node is updated, thereby permitting continuous deployment of changes.

``` ```

## 0. Create a services account

In GCP compute engine, create a master node. Next, create a services account with owner permissions and copy the .json key into ```~/creds/serviceaccount.json``` on the master node.

## 1. Configure master node

Configure the firewalls on the master node to pass in http traffic on port ```80``` and jenkins on port ```8080```.

## 2. Install prerequisite plugins

Install java, wget, git, unzip, docker and kubernetes on the master node with the following command:

```sudo yum install -y java wget git unzip docker kubectl```

## 3. Install Terraform

Install Terraform on to the master node. Fetch the link from the website for linux-64-bit and ```wget``` it. Unzip the folder and move the resultant file to the local binaries, as such:

```sudo mv terraform /usr/local/bin```

## 4. Terraform Cluster Creation

On the master node, authenticate with google cloud and follow the instructions:

```gcloud auth login```

Fork the above main repository and ```git clone``` the forked repository on to the master node. ```cd``` into the ```cluster``` folder and run:

```terraform init```

Create the cluster with:

```terraform apply -auto-approve```

Upon completion, fetch the credentails so that we can interact with the cluster using ```kubectl``` commands:

```
gcloud config set project <Project Name>
gcloud container clusters get-credentials --region europe-west1-b gke-cluster
```

Running these commands will set the active project to your ```<Project Name>```, and the ```gcloud container clusters get-credentials``` updates the ```kubeconfig``` file with new end-point data so that your active clusters in GKE can now be queried by ```kubectl```.

## 5. Configure docker

Configure docker by placing root user into the docker group. This way, we will not have to use ```sudo``` every time we try to run a docker command. First, on the master node create the docker group:

```sudo groupadd docker```

Place the root user into the docker group:

```sudo usermod -aG docker $USER```

Restart the master node through GCP so new user permissions for the docker group take effect.

## 6. Install jenkins

On the master node install jenkins (CentOS-7):

```
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum install -y jenkins
```

Place the jenkins user into the docker group. If this is not done then jenkins will not run docker commands as jenkins cannot run as sudo:

```sudo usermod -aG docker jenkins```

Restart the master node so new user permissions for the docker group take effect. Upon restarting, start the jenkins service:

```sudo service jenkins start```

Copy the master node's ip into the browser as ```<master node ip>:8080``` and follow the instructions to setting up a user account for jenkins. If the service is not up, redo step #1 and instead allow all ports, not just ```8080```, and attempt to reconnect.

## 7. Setting up docker containers for hellowhale

On the master node start the docker service:

```sudo service docker start```

```cd``` into the Jenkins-CI-CD_Kubernetes folder and build the docker image and push to dockerhub:

```
docker build . -t hellowhale
docker tag hellowhale <Your Dockerhub Account>/hellowhale
docker login -u <Your Dockerhub Account> -p <Your Dockerhub Password>
docker push <Your Dockerhub Account>/hellowhale
```

## 8. Create k8s cluster for hellowhale deployment

On the master node create a deployment for the docker image:

```kubectl create deployment hellowhale --image <Your Dockerhub Account>/hellowhale```

Expose the deployment with ```--type LoadBalancer```:

```kubectl expose deployment/hellowhale --port 80 --name hellowhalesvc --type LoadBalancer```

Run ```kubectl get svc``` to see the ip address for the above LoadBalancer, enter it into the browser to see the webpage.

## 9. Configure jenkins in the console

Copy the ```/home/$USER/.kube/config``` file to ```/var/lib/jenkins/.kube```. If the ```/.kube``` directory in ```/var/lib/jenkins/.kube``` does not exist then create it. Use sudo when copying, as such:

```sudo cp /home/$USER/.kube/config /var/lib/jenkins/.kube/```

Change ownership of the above file so that jenkins owns it and make it executable, without doing so we cannot run ```kubectl``` commands:

```
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
sudo chmod +x /var/lib/jenkins/.kube/config
```

Restart the jenkins service:

```sudo service jenkins restart```

## 10. Configure Jenkins in the browser

We have just restarted the Jenkins server on the master node, so the Jenkins webpage will need time to become accessible again. Once Jenkins is accessible, login to Jenkins in the browser and navigate to ```Manage Jenkins > Configure System```. Under ```Global Properties``` tick environment variables and put ```DOCKER_HUB``` under ```Name``` and your dockerhub password under ```Value```.

Under ```Jenkins Location``` in the ```Jenkins URL``` put ```http://<master node ip>:8080/```.

Under ```Github``` click "Advanced" and tick "Specify another hook URL for GitHub configuration" and insert into the box that appears:
```http://<master node ip>:8080/github-webhook/```. This will allow triggering of builds and deployments on git commits.

Click save.

## 11. Configure Github webhooks

In your Github repository that you forked in step #4, navigate to ```Settings``` and click on the ```webhooks``` pane. Click ```Add Webhook``` and under the payload url enter ```http://<master node ip>:8080/github-webhook/```, and in the drop down menu select ```application/json```. When done, click Add Webhook.

## 12. Create a Jenkins job

Create a jenkins job, and click ```Github Project```, enter the url of your github repository.

Under Source Code Management click ```git``` and insert the github for your repo again.

The Build Triggers will trigger a build on each github commit. Under Build Triggers tick "GitHub hook trigger for GITScm polling".

In the Build sections, create an ```execute shell``` with the following code:

```
IMAGE_NAME="<Your Dockerhub Account>/hellowhale:${BUILD_NUMBER}"
docker build . -t $IMAGE_NAME
docker login -u <Your Dockerhub Account> -p ${DOCKER_HUB}
docker push $IMAGE_NAME
```

This will build an image and push it to Dockerhub on each commit. Create another ```execute shell`` and enter the below code:

```
IMAGE_NAME="<Your Dockerhub Account>/hellowhale:${BUILD_NUMBER}"
kubectl set image deployment/hellowhale hellowhale=$IMAGE_NAME
```

This will reset the deployment image on each commit. We are now finished with the pipeline, let us test it.

## 13. Testing pipeline

Make a notable change to the ```html/index.html``` on the master node. Then run:

```git add html/index.html```

Commit the changes and follow the instructions for git authentication:

```git commit -m "Change"```

Finally ```git push```. Quickly switch to the jenkins browser and click on your project. You should see a progress bar, when it is complete go to your browser and enter the LoadBalancer's ip into the search bar (as in the last step of step #6). You should see the changes you commited to Github.
