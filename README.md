# example-terraform

Hi and thanks for looking in.

These are some examples for how to setup and use Terraform.

The examples are broken down into where they work :
- Azure
- aws
- gcp
- ovh
and for things that are not just host centric 
- misc

In most of them, inside modules we have the code that creates the items (resourses).

Inside env you would create a setup for each environment you would like to have, for example - 
- test
- qa
- production

the main file that changes in each of these is variables.tf





