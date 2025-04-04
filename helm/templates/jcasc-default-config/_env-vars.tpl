
{{/*
Default config script for global environment variables
*/}}
{{- define "jenkins.casc.defaults.env-vars" -}}
{{- $configScripts := toYaml .Values.JCasC.configScripts -}}
  {{- if not (contains "globalNodeProperties:" $configScripts) }}
jenkins:
  # Configure System > Global properties
  globalNodeProperties:
    - envVars:
    {{- if .Values.JCasC.envVars }}
        env:
      {{- range $key, $value := .Values.JCasC.envVars }}
          - key: {{ $key | quote }}
            value: {{ tpl $value $ | trim | quote }}
      {{- end }}
    {{- else }}
        env: []
    {{- end }}
  {{- end }}
{{- end -}}
