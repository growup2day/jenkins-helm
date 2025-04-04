
{{/*
Returns configuration as code default config
*/}}
{{- define "jenkins.casc.defaults.openshift-sync" -}}
{{- $configScripts := toYaml .Values.JCasC.configScripts -}}
  {{- if not (contains "globalPluginConfiguration:" $configScripts) }}
unclassified:
  # Configure System > OpenShift Jenkins Sync
  globalPluginConfiguration:
    enabled: {{ .Values.JCasC.openshiftSync.enabled }}
  {{- end }}

{{- end -}}
