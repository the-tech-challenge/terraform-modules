# TFLint Configuration
# Disable module pinning warning for development
# In production, you should pin to specific version tags

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_module_pinned_source" {
  enabled = false
}
