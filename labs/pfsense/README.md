# pfSense Image deploy and configuration

pfSense was used in some of the labs. Below are the steps to create a pfSense image in GCP, install the image, and lastly configure it.

| Steps | Deployment |
| ------| ---------- |
| [00-create-image](./00-create-image) | Steps to download pfSense, upload into a GCS bucket and create an image |
| [01-pfsense-install](./01-pfsense-install) | Steps to install pfSense from the Serial console |
| [02-pfsense-configure](./02-pfsense-configure) | Steps to configure the pfSense firewall from a web browser |