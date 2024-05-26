# example-terraform

Hi and thanks for looking in.

These are some examples for how to setup Terraform to work in AWS.

Inside modules we have the code that creates the items (resourses).

There is code to 
- create ECS cluster
- setup cloud watch monitors
- create a zabbix setup
- Watch for aws account issues like billing (still in beta)

Inside env you would create a setup for each environment you would like to have, for example - 
- test
- qa
- production

the main file that changes in each of these is variables.tf





