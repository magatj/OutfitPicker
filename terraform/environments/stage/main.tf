module "ecr" {
  source      = "../../modules/ecr"
  app_name    = var.app_name
  environment = var.environment
}

module "auth" {
  source      = "../../modules/auth"
  app_name    = var.app_name
  environment = var.environment
}

module "storage" {
  source       = "../../modules/storage"
  app_name     = var.app_name
  environment  = var.environment
  cors_origins = [var.cors_origins]
}

module "database" {
  source                     = "../../modules/database"
  app_name                   = var.app_name
  environment                = var.environment
  enable_pitr                = false
  enable_deletion_protection = false
}

module "iam" {
  source             = "../../modules/iam"
  app_name           = var.app_name
  environment        = var.environment
  uploads_bucket_arn = module.storage.uploads_bucket_arn
  table_arn          = module.database.table_arn
  queue_arn          = module.queue.queue_arn
}

module "queue" {
  source              = "../../modules/queue"
  app_name            = var.app_name
  environment         = var.environment
  lambda_role_arn     = module.iam.lambda_role_arn
  app_runner_role_arn = module.iam.app_runner_role_arn
  uploads_bucket      = module.storage.uploads_bucket_name
  table_name          = module.database.table_name
}

module "backend" {
  source                     = "../../modules/backend"
  app_name                   = var.app_name
  environment                = var.environment
  aws_region                 = var.aws_region
  ecr_image_uri              = var.ecr_image_uri
  cpu                        = var.app_runner_cpu
  memory                     = var.app_runner_memory
  app_runner_role_arn        = module.iam.app_runner_role_arn
  app_runner_access_role_arn = module.iam.app_runner_access_role_arn
  table_name                 = module.database.table_name
  uploads_bucket             = module.storage.uploads_bucket_name
  queue_url                  = module.queue.queue_url
  cognito_pool_id            = module.auth.user_pool_id
  cors_origins               = var.cors_origins
}

module "frontend" {
  source      = "../../modules/frontend"
  app_name    = var.app_name
  environment = var.environment
}

module "monitoring" {
  source              = "../../modules/monitoring"
  app_name            = var.app_name
  environment         = var.environment
  dlq_name            = "${var.app_name}-${var.environment}-detection-dlq"
  log_retention_days  = 14
}
