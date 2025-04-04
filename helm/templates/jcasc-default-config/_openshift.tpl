
{{/*
Default config script for OpenShift plugin
*/}}
{{- define "jenkins.casc.defaults.openshift" -}}
{{- $configScripts := toYaml .Values.JCasC.configScripts -}}
  {{- if not (contains "openShift:" $configScripts) }}
unclassified:
  # Configure System > OpenShift Client Plugin
  openShift:
    {{- if .Values.JCasC.openshiftClouds }}
    clusterConfigs:
      {{- range $key, $value := .Values.JCasC.openshiftClouds }}
      - name: {{ $key }}
        serverUrl: {{ tpl $value.serverUrl $ | quote }}
        defaultProject: {{ tpl $value.namespace $ | quote }}
        skipTlsVerify: {{ default false $value.skipTlsVerify }}
      {{- end }}
    {{- else }}
    clusterConfigs: []
    {{- end }}
  {{- end }}
{{- end -}}
