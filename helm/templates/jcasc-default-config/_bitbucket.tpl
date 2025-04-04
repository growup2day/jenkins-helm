
{{/*
Default config script for BitBucket
*/}}
{{- define "jenkins.casc.defaults.bitbucket" -}}
{{- $configScripts := toYaml .Values.JCasC.configScripts -}}
  {{- if not (contains "bitbucketEndpointConfiguration:" $configScripts) }}
unclassified:
  # Configure System > Bitbucket Endpoints
  bitbucketEndpointConfiguration:
    {{- if .Values.JCasC.anzBitbucket.enabled }}
    endpoints:
      - bitbucketServerEndpoint:
          displayName: "ANZ_Bitbucket"
          serverUrl: "https://bitbucket.nz.service.anz"
          manageHooks: {{ .Values.JCasC.anzBitbucket.manageHooks }}
          {{- if .Values.JCasC.anzBitbucket.manageHooks }}
          credentialsId: {{ .Values.JCasC.anzBitbucket.credentialsId | quote }}
          {{- end }}
    {{- else }}
    endpoints: []
    {{- end }}
  {{- end }}
{{- end -}}
