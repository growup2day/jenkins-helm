
{{/*
Default config script for script approval
*/}}
{{- define "jenkins.casc.defaults.script-approval" -}}
{{- $configScripts := toYaml .Values.JCasC.configScripts -}}
  {{- if not (contains "approvedSignatures:" $configScripts) }}
security:
  # In-process Script Approval
  scriptApproval:
    {{- if .Values.JCasC.scriptApproval }}
    approvedSignatures:
      {{- range $index, $val := .Values.JCasC.scriptApproval }}
        - {{ $val | quote }}
      {{- end }}
    {{- else }}
    approvedSignatures: []
    {{- end }}
  {{- end }}
{{- end -}}
