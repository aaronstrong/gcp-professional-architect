
#### Enable Cloud Identity Aware Proxy API
```bash
gcloud config set project `PROJECT_ID`
gcloud services list --available
gcloud services enable iap.googleapis.com 
```

#### Create firewall rule
```bash
gcloud compute firewall-rules create allow-ssh-ingress-from-iap \
  --direction=INGRESS \
  --action=allow \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20
```

#### Create permissions to use IAP TCP forwarding
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member=user:EMAIL \
    --role=roles/iap.tunnelResourceAccessor
```

#### Tunneling SSH connections

```bash
gcloud compute ssh `INSTANCE_NAME`
```
* Replace `INSTANCE_NAME` with the name of the instance to SSH into.
* You can use the `--tunnel-through-iap` flag so that `glcoud compute ssh` always uses IAP TCP tunneling