locals {
  platform_hosts = {
    US1  = "qg1.apps.qualys.com"
    US2  = "qg2.apps.qualys.com"
    US3  = "qg3.apps.qualys.com"
    US4  = "qg4.apps.qualys.com"
    GOV1 = "gov1.qualys.us"
    EU1  = "qg1.apps.qualys.eu"
    EU2  = "qg2.apps.qualys.eu"
    EU3  = "qg3.apps.qualys.it"
    IN1  = "qg1.apps.qualys.in"
    CA1  = "qg1.apps.qualys.ca"
    AE1  = "qg1.apps.qualys.ae"
    UK1  = "qg1.apps.qualys.co.uk"
    AU1  = "qg1.apps.qualys.com.au"
    KSA1 = "qg1.apps.qualysksa.com"
  }

  platform_host     = local.platform_hosts[var.qualys_platform]
  gateway_url       = var.gateway_url != null ? var.gateway_url : "https://gateway.${local.platform_host}"
  cmsqag_public_url = var.cmsqag_public_url != null ? var.cmsqag_public_url : "https://cmsqagpublic.${local.platform_host}/ContainerSensor"

  enabled_components = [
    for name in ["cluster_sensor", "qcs_sensor", "runtime_sensor", "admission_controller"] :
    name if var.components[name]
  ]
}
