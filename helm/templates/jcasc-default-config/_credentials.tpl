
{{/*
Default config script for credentials
*/}}
{{- define "jenkins.casc.defaults.credentials" -}}
{{- $configScripts := toYaml .Values.JCasC.configScripts -}}
  {{- if not (contains "domainCredentials:" $configScripts) }}
# Manage Credentials
credentials:
  system:
    domainCredentials:
    {{- if .Values.JCasC.vault.enabled }}
      - credentials:
          - vaultKubernetesCredential:
              description: "Vault Auth"
              id: {{ .Values.JCasC.vault.credentialId | quote }}
              mountPath: {{ .Values.JCasC.vault.mountPath | quote }}
              role: {{ .Values.JCasC.vault.role | quote }}
              scope: {{ .Values.JCasC.vault.scope | default "SYSTEM" | quote }}
      {{- if .Values.JCasC.vault.credentials }}
        {{- range $key, $value := .Values.JCasC.vault.credentials }}
          - {{ $value.kind }}:
              id: {{ $key | quote }}
              {{- tpl (toYaml (unset $value "kind")) $ | nindent 14 }}
        {{- end }}
      {{- end }}
    {{- else }}
      - credentials: []
    {{- end }}
  {{- end }}

{{- end -}}
