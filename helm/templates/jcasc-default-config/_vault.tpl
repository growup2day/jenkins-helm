
{{/*
Default config script for Hashicorp Vault integration
*/}}
{{- define "jenkins.casc.defaults.vault" -}}
{{- $configScripts := toYaml .Values.JCasC.configScripts -}}
  {{- if and (not (contains "hashicorpVault:" $configScripts)) .Values.JCasC.vault.enabled }}
unclassified:
  # Configure System > Vault Plugin
  hashicorpVault:
    configuration:
    {{- if .Values.JCasC.vault.namespace }}
      engineVersion: 2
      timeout: 10
      vaultCredentialId: {{ .Values.JCasC.vault.credentialId | quote }}
      vaultNamespace: {{ .Values.JCasC.vault.namespace | quote }}
      vaultUrl: {{ .Values.JCasC.vault.vaultUrl | quote }}
    {{- else }}
      vaultCredentialId: ""
      vaultNamespace: ""
      vaultUrl: ""
    {{- end }}
  {{- end }}
{{- end -}}
