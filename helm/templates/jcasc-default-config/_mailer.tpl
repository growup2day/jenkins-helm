
{{/*
Default config script for Mailer plugin
*/}}
{{- define "jenkins.casc.defaults.mailer" -}}
{{- $configScripts := toYaml .Values.JCasC.configScripts -}}
  {{- if not (contains "mailer:" $configScripts) }}
unclassified:
  # Configure System > E-mail Notification
  mailer:
    {{- if .Values.JCasC.mailer.smtpHost }}
    charset: "UTF-8"
    useSsl: false
    useTls: false
    smtpHost: {{ .Values.JCasC.mailer.smtpHost | quote }}
    smtpPort: {{ .Values.JCasC.mailer.smtpPort | quote }}
    {{- else }}
    smtpHost: ""
    {{- end }}
  {{- end }}
{{- end -}}
