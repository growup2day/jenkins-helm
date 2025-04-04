
{{/*
Default config script for Kubernetes cloud
*/}}
{{- define "jenkins.casc.defaults.clouds" -}}
{{- $configScripts := toYaml .Values.JCasC.configScripts -}}
  {{- if not (contains "clouds:" $configScripts) }}
jenkins:
  # Manage Nodes and Clouds > Configure Clouds
    {{- if .Values.JCasC.openshiftClouds }}
  clouds:
      {{- range $key, $value := .Values.JCasC.openshiftClouds }}
    - kubernetes:
        name: {{ $key }}
        serverUrl: {{ tpl $value.serverUrl $ | quote }}
        namespace: {{ tpl $value.namespace $ | quote }}
        {{- if $value.credentialsId }}
        credentialsId: {{ tpl $value.credentialsId $ | quote }}
        {{- end }}
        {{- if $value.webSocket }}
        webSocket: {{ $value.webSocket }}
        {{- else }}
          {{- if $.Values.jnlpService.nodePort }}
        jenkinsTunnel: {{ printf "%s:%d" (include "jenkins.routeHost" $) (int $.Values.jnlpService.nodePort) | quote }}
          {{- else }}
        jenkinsTunnel: {{ printf "%s.%s.svc.cluster.local:%s" (include "jenkins.jnlpServiceName" $) $.Release.Namespace (include "jenkins.jnlpPort" $) | quote }}
          {{- end }}
        {{- end }}
        jenkinsUrl: {{ printf "https://%s" (include "jenkins.routeHost" $) | quote }}
        {{- if $value.defaultsProviderTemplate }}
        defaultsProviderTemplate: {{ $value.defaultsProviderTemplate | quote }}
        {{- end }}

        {{- if .simpleTemplates }}
        templates:
          {{- $simpleTemplates := .simpleTemplates -}}
          {{- range $templateKey, $templateValue := .simpleTemplates.templates }}
          - name: {{ $templateKey | quote }}
            label: {{ $templateValue.label | quote }}
            nodeSelector: "beta.kubernetes.io/os=linux"
            serviceAccount: {{ default (include "jenkins.serviceAccountName" $) $templateValue.serviceAccount | quote }}
            {{- $podAttributes := merge (default (dict) $templateValue.podAttributes) (default (dict) $simpleTemplates.commonPodAttributes) }}
            {{- if $podAttributes }}
              {{- tpl (toYaml $podAttributes) $ | nindent 12 }}
            {{- end }}
            containers:
              - name: "jnlp"
            {{- if $templateValue.useGoInit }}
                command: "/usr/bin/go-init"
                args: "-main \"/usr/local/bin/run-jnlp-client {{ if $value.webSocket }}-webSocket {{ end }}^${computer.jnlpmac} ^${computer.name}\""
            {{- else }}
                command: "/usr/local/bin/run-jnlp-client"
                args: "{{ if $value.webSocket }}-webSocket {{ end }}^${computer.jnlpmac} ^${computer.name}"
            {{- end }}
                image: {{ printf "%s/%s" (default (include "jenkinsSlaveImage.registry" $ ) $templateValue.image.registry) (default (include "jenkinsSlaveImage.path" $ ) $templateValue.image.path) | quote }}
            {{- $containerAttributes := merge (default (dict) $templateValue.containerAttributes) (default (dict) $simpleTemplates.commonContainerAttributes) }}
            {{- if $containerAttributes }}
              {{- tpl ($containerAttributes | toYaml) $ | nindent 16 }}
            {{- end }}
            {{- $envVars := merge (default (dict) $templateValue.envVars) (default (dict) $simpleTemplates.commonEnvVars) }}
            {{- if $envVars }}
                envVars:
              {{- range $envVarKey, $envVarValue := $envVars }}
                  - envVar:
                      key: {{ $envVarKey | quote }}
                      value: {{ tpl $envVarValue $ | quote }}
              {{- end }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- else }}
  clouds: []
    {{- end }}
  {{- end }}
{{- end -}}
