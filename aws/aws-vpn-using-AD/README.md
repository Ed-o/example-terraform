# Setup an AWS Client VPN using Azure AD to get users 

Uses Terraform



Set up an AWS Client VPN using Azure AD as the identity provider.

Add an AWS VPN from the templates

In Getting started.
1.	Assign users or groups to be allowed to use this
2.	Set up SSO :
(note you will need to put in the 127.0.0.1 as ‘https://127...’ that is all it will allow.

![picture of the MS settings](docs/picture1.png)

3.	Download the Federation XML (this is the ad file put into aws IAM)
4.	Click on ‘App registrations’ on left menu 
Find app by searchiong for it and click on and on Manifest
edit file and replace https://127.0.0.1:35001 -> http://127...



