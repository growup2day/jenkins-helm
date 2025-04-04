
{{/*
Default config script for Slack integration
*/}}
{{- define "jenkins.casc.defaults.slack" -}}
{{- $configScripts := toYaml .Values.JCasC.configScripts -}}
  {{- if not (contains "slackNotifier:" $configScripts) }}
unclassified:
  # Configure System > Slack
  slackNotifier:
    {{- if .Values.JCasC.slackNotifier.credentialId }}
    botUser: false
    sendAsText: false
    teamDomain: "anznz"
    tokenCredentialId: {{ .Values.JCasC.slackNotifier.credentialId | quote }}
    {{- else }}
    teamDomain: ""
    tokenCredentialId: ""
    {{- end }}
  {{- end }}
{{- end -}}
