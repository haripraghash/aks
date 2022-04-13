locals {
  prefix = "hariaks"
  //group_prefix               = title("${var.bank} ${var.environment}")
  environment_domain               = "${local.prefix}.${var.parent_domain.domain}"
  environment_domain_private       = "${local.prefix}-private.${var.parent_domain.domain}"
  environment_domain_piper_private = "piper.${local.prefix}-private.${var.parent_domain.domain}"

  terraform_last_run_date = formatdate("DD-MM-YYYY", timestamp())
}