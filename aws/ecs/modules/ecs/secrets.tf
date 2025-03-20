# Lets use AWS secrets for things that people should not easily see

# == Databases ==

locals {
  # Lets set up the usernames and passwords
  # If they exist in secrets we use them.  if not we get them from default AWS secrets.

  # First the master or root database user (if it is not set get from aws-secret : database_master_username<-env>
  database_master_username = (var.secrets.database_master_username != "") ? var.secrets.database_master_username : data.aws_secretsmanager_secret_version.database_master_username[0].secret_string

  # Next the master or root password (or if not set use aws-secret : database_master_password<-env>)
  database_master_password = (var.secrets.database_master_password != "") ? var.secrets.database_master_password : data.aws_secretsmanager_secret_version.database_master_password[0].secret_string

  # Next the name of the database  (or if not set use aws-secret : database_app_database<-env>)
  database_app_database = (var.secrets.database_app_database != "") ? var.secrets.database_app_database : data.aws_secretsmanager_secret_version.database_app_database[0].secret_string

  # Next the app database username  (or if not set use aws-secret : database_app_username<-env>)
  database_app_username = (var.secrets.database_app_username != "") ? var.secrets.database_app_username : data.aws_secretsmanager_secret_version.database_app_username[0].secret_string

  # Next the app database password  (or if not set use aws-secret : database_app_password<-env>)
  database_app_password = (var.secrets.database_app_password != "") ? var.secrets.database_app_password : data.aws_secretsmanager_secret_version.database_app_password[0].secret_string
}

# And here is where we collect the keys from the AWS Secrets vault (if needed)
data "aws_secretsmanager_secret" "database_master_username" {
  count = (var.secrets.database_master_username == "") ? 1 : 0
  name = "database_master_username${local.sharedname}"
}
data "aws_secretsmanager_secret_version" "database_master_username" {
  count = (var.secrets.database_master_username == "") ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.database_master_username[0].id
}

data "aws_secretsmanager_secret" "database_master_password" {
  count = (var.secrets.database_master_password == "") ? 1 : 0
  name = "database_master_password${local.sharedname}"
}
data "aws_secretsmanager_secret_version" "database_master_password" {
  count = (var.secrets.database_master_password == "") ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.database_master_password[0].id
}

data "aws_secretsmanager_secret" "database_app_database" {
  count = (var.secrets.database_app_database == "") ? 1 : 0
  name = "database_app_database${local.sharedname}"
}
data "aws_secretsmanager_secret_version" "database_app_database" {
  count = (var.secrets.database_app_database == "") ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.database_app_database[0].id
}

data "aws_secretsmanager_secret" "database_app_username" {
  count = (var.secrets.database_app_username == "") ? 1 : 0
  name = "database_app_username${local.sharedname}"
}
data "aws_secretsmanager_secret_version" "database_app_username" {
  count = (var.secrets.database_app_username == "") ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.database_app_username[0].id
}

data "aws_secretsmanager_secret" "database_app_password" {
  count = (var.secrets.database_app_password == "") ? 1 : 0
  name = "database_app_password${local.sharedname}"
}
data "aws_secretsmanager_secret_version" "database_app_password" {
  count = (var.secrets.database_app_password == "") ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.database_app_password[0].id
}





# == AWS Credentials ==

locals {
  # AWS_ACCESS_KEY_ID
  aws_access_key_id = var.secrets.aws_access_key_id 

  # AWS_SECRET_ACCESS_KEY
  aws_secret_access_key = (var.secrets.aws_secret_access_key == "<secret>") ? data.aws_secretsmanager_secret_version.aws_secret_access_key[0].secret_string : ""

}

# And here is where we collect the keys from the AWS Secrets vault (if needed)
data "aws_secretsmanager_secret" "aws_secret_access_key" {
  count = (var.secrets.aws_secret_access_key == "<secret>") ? 1 : 0
  name = "aws_secret_access_key_all3082"
}
data "aws_secretsmanager_secret_version" "aws_secret_access_key" {
  count = (var.secrets.aws_secret_access_key == "<secret>") ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.aws_secret_access_key[0].id
}



