
{{/*
Default config script for permanent nodes
*/}}
{{- define "jenkins.casc.defaults.nodes" -}}
{{- $configScripts := toYaml .Values.JCasC.configScripts -}}
  {{- if not (contains "nodes:" $configScripts) }}
jenkins:
  # Manage Nodes and Clouds > Manage Nodes
    {{- if .Values.JCasC.permanentNodes.enabled }}
  nodes:
      {{- range $key, $value := .Values.JCasC.permanentNodes.agents }}
      {{- $defaultNodeDescription := printf "%s%s" "Permanent node " (default "" $value.host) }}
    - permanent:
        name: {{ $key | quote }}
        nodeDescription: {{ (default $defaultNodeDescription $value.nodeDescription) | quote }}
        labelString: {{ (default "" $value.labelString) | quote }}
        launcher:
        {{- if eq (default "ssh" $value.launcherType) "jnlp" }}
          jnlp:
            tunnel: {{ (default "" $value.jnlpTunnel) | quote }}
        {{- else }}
          ssh:
            credentialsId: {{ (default "" $value.credentialsId) | quote }}
            host: {{ (default "" $value.host) | quote }}
            port: 22
            {{- if $value.javaPath }}
            javaPath: {{ $value.javaPath | quote }}
            {{- end }}
            sshHostKeyVerificationStrategy:
              manuallyProvidedKeyVerificationStrategy:
                key: {{ .hostKey | quote }}
        {{- end }}
        {{- if $value.remoteFS }}
        remoteFS: {{ $value.remoteFS | quote }}
        {{- if $.Values.JCasC.permanentNodes.commonAttributes.remoteFS }}
          {{ fail "To avoid duplicate config keys, either define remoteFS for an agent, or add it to the commonAttributes, but not both." }}
        {{- end }}
        {{- end }}
        {{- if $.Values.JCasC.permanentNodes.commonAttributes }}
          {{- tpl (toYaml $.Values.JCasC.permanentNodes.commonAttributes) $ | nindent 8 }}
        {{- end }}
      {{- end }}
    {{- else }}
  nodes: []
    {{- end }}
  {{- end }}

{{- end -}}
