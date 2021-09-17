# [Deploying a simple app to GKE](https://cloud.google.com/kubernetes-engine/docs/tutorials/hello-app#cloud-shell)

## Create a GKE Cluster

Terraform code can be found in the `main.tf` file.

## Connect to the cluster

Configure `kubectl` command line access by running the following command:

`gcloud container clusters get-credenteials my-gke-cluster --region us-central1 --project <PROJECT ID>`

After Terraform has completed, run the following command to see the cluster's nodes:

`kubectl get nodes`

## Deploying the sample app to GKE

1. Ensure you are connected to the cluster.
1. Create a Kubernetes Deployment for your `hello-app` Docker image.
`kubectl create deployment hello-app --image=us-central1`
1. 


nginx:latest