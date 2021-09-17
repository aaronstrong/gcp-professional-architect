# How to install pfSense

After the [pfSense image has been created](../create-pfsense-image/), now install pfSense.

1. Navigate to the Compute Engine.
1. Select the Serial Console button. This will launch a new dialog window.
1. Follow the screenshots to install:

<img src="../../../images/pfsense-install/image1.png" width="300">

<img src="../../../images/pfsense-install/image2.png" width="300">

<img src="../../../images/pfsense-install/image3.png" width="300">

<img src="../../../images/pfsense-install/image4.png" width="300">

<img src="../../../images/pfsense-install/image5.png" width="300">

<img src="../../../images/pfsense-install/image6.png" width="300">

<img src="../../../images/pfsense-install/image7.png" width="300">

Make sure you select `Cancel`<br>
<img src="../../../images/pfsense-install/image9.png" width="300">

<img src="../../../images/pfsense-install/image9b.png" width="300">

<img src="../../../images/pfsense-install/image10.png" width="300">

<img src="../../../images/pfsense-install/image12.png" width="300">

<img src="../../../images/pfsense-install/image13.png" width="300">

<img src="../../../images/pfsense-install/image15.png" width="300">

"Should VLANs be setup now": No<br>
<img src="../../../images/pfsense-install/image16.png" width="300">

type in `vtnet0`<br>
<img src="../../../images/pfsense-install/image18.png" width="300">

Hit Enter<br>
<img src="../../../images/pfsense-install/image18a.png" width="300">

"Do you want to proceed": Yes<br>
<img src="../../../images/pfsense-install/image18b.png" width="300">

<img src="../../../images/pfsense-install/image19.png" width="300">

Select option 8<br>
type in `pfSh.php playbook disablereferercheck`<br>
<img src="../../../images/pfsense-install/image20.png" width="300">

Open up a browswer and connect to the public IP address of the instance.

| Credentials | Default |
| ----------- | ------- |
| username    | admin   |
| password    | pfsense |