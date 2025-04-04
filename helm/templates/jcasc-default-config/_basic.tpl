
{{/*
Default config script for basic Jenkins configuration.
Due to the field names not being unique enough, these are not overridable by custom scripts.
*/}}
{{- define "jenkins.casc.defaults.basic" -}}
{{- $configScripts := toYaml .Values.JCasC.configScripts }}
jenkins:
  # Configure System > Maven Project Configuration
  mode: {{ .Values.JCasC.master.mode | quote }}
  numExecutors: {{ .Values.JCasC.master.numExecutors }}
unclassified:
  # Configure System > Jenkins Location
  location:
    url: {{ printf "https://%s/" (include "jenkins.routeHost" .) | quote }}
    adminAddress: {{ .Values.JCasC.adminAddress | quote }}
{{- end -}}
