components = {
  cluster_sensor       = true
  qcs_sensor           = true
  runtime_sensor       = true
  admission_controller = true
}
sensor_tags = ["render-check"]
admission_controller = {
  enforcement_action = "Audit"
}
runtime_sensor = {
  process_allow_list = ["/*/curl", "/*/wget"]
}
