locals {
  ingress_rules = merge([
    for sg_name, sg in var.security_group : {
      for rule_name, rule in sg.ingress :
      "${sg_name}-${rule_name}" => {
        sg_name = sg_name
        rule    = rule
      }
    }
  ]...)
}
