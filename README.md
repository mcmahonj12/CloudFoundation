# CloudFoundation
Automation used in CloudFoundation

This PowerShell script can be used to deploy Cloud Builder used by VMware Cloud Foundation 3.x. Because Cloud Builder is a 1:1 deployment for each bringup, you can store the configuration information in the config.json file to deploy multiple instances. This script is menu driven and will ask the user which Cloud Builder intance to deploy based on the items stored in the config.json.

It could be modified to perform mass deployments of Cloud Builder as well when automating the full lifecycle of:
- Host Prep
- Bringup
- Post configurations not performed by Cloud Foundation

This is especially useful when testing Cloud Foundation.

Hi