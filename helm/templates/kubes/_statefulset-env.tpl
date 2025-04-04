
{{/*
Template for setting environment variables in OpenShift on the Stateful Set.
*/}}
{{- define "kubes.defaults.env" -}}
  {{- if .Values.env }}
    {{- range $key, $value := .Values.env }}
      - name: {{ tpl $key $ }}
        value: {{ tpl $value $ | quote }}
    {{- end }}
  {{- end }}
{{- end -}}