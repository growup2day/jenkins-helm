
{{/*
Default config script for pipeline libraries
*/}}
{{- define "jenkins.casc.defaults.libraries" -}}
{{- $configScripts := toYaml .Values.JCasC.configScripts -}}
  {{- if not (contains "globalLibraries:" $configScripts) }}
unclassified:
  # Configure System > Global Pipeline Libraries
  globalLibraries:
    {{- if .Values.JCasC.pipelineLibraries }}
    libraries:
      {{- range $key, $value := .Values.JCasC.pipelineLibraries }}
      - name: {{ $key | quote }}
        defaultVersion: "master"
        includeInChangesets: {{ default false $value.includeInChangesets }}
        retriever:
          modernSCM:
            scm:
              git:
                {{- if $value.credentialsId }}
                credentialsId: {{ $value.credentialsId | quote }}
                {{- end }}
                remote: {{ $value.repo | quote }}
                traits:
                  - "gitBranchDiscovery"
      {{- end }}
    {{- else }}
    libraries: []
    {{- end }}
  {{- end }}
{{- end -}}
