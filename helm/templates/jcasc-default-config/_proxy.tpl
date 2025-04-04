
{{/*
Default config script for proxy
*/}}
{{- define "jenkins.casc.defaults.proxy" -}}
{{- $configScripts := toYaml .Values.JCasC.configScripts }}
  {{- if not (contains "proxy:" $configScripts) }}
jenkins:
  # Manage Plugins > Advanced
  proxy:
    {{- if .Values.JCasC.master.proxy }}
      {{- tpl (toYaml .Values.JCasC.master.proxy) $ | nindent 4 }}
    {{- end }}
  {{- end }}
{{- end -}}
