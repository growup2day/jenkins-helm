
{{/*
Default config script for putting Jenkins in-to/out-of "quiet down" mode (where no new build gets scheduled)
*/}}
{{- define "jenkins.casc.defaults.quiet-down" -}}
{{- with .Values.JCasC.quietDown }}
  {{- if .enableScript }}
groovy:
  - script: |
      def quietDown = {{ .quietDown }}
      def jenkins = jenkins.model.Jenkins.get()
      def quietDownMessage = {{ .quietDownMessage | quote}}
      if (quietDown) {
        if (!jenkins.isQuietingDown() ||
            jenkins.getQuietDownReason() != quietDownMessage) {
          // puts Jenkins into quietdown/shutdown mode, without waiting for existing builds to complete (block=false)
          jenkins.doQuietDown(false, 0, quietDownMessage)
        }
      } else {
        if (jenkins.isQuietingDown()) {
          jenkins.doCancelQuietDown()
        }
      }
  {{- end }}
{{- end }}
{{- end }}
