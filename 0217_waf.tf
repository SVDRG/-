resource "azurerm_web_application_firewall_policy" "team63_waf" {
  name                = "team63-waf-policy"
  resource_group_name = var.rgname
  location            = var.rgloca

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
  depends_on = [azurerm_resource_group.team603_snort_central]
}

resource "azurerm_web_application_firewall_policy" "team63_waf2" {
  name                = "team63-waf2-policy"
  resource_group_name = var.rgname2
  location            = var.rgloca2

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
  depends_on = [azurerm_resource_group.team603_snort_jpwest]
}
