[Flags()] enum ProGetApiKeySystemApis {
    feeds = 1
    sca = 2
    sbom_upload = 4
    full_control = 7  # Full control is the combination of all other values
}