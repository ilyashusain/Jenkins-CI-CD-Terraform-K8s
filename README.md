# Outline of Solution

We will create a master node. On the master node we will install terraform to help spin up a cluster. We will then fetch the credentials for our cluster which will allow us to interact with the cluster using the ```kubectl``` commands. Then we will deploy an application on to one of the cluster nodes using ```kubectl```.

Also on our master node is a jenkins controller that waits for commit requests from Github. On each commit, the deployment on the cluster node is updated.

For a detailed guide, see the encased README in the Jenkins_CD-CD_Kubernetes.