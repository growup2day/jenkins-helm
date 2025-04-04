{{/*
Expand the name of the chart.
*/}}
{{- define "jenkins.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at (63-16)=47 chars to leave room for object names that are based on this (e.g. <fullname>-jnlp)
because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "jenkins.fullname" -}}
{{- if contains .Chart.Name .Release.Name }}
{{- .Release.Name | trunc 47 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 47 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "jenkins.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create jenkins image reference
*/}}
{{- define "jenkins.image" -}}
{{- printf "%s/%s:%s" (default .Values.defaultImageRegistry .Values.image.registry) .Values.image.repository (default .Chart.AppVersion .Values.image.tag) }}
{{- end }}

{{- define "jenkinsSlaveImage.registry" -}}
{{- default (default .Values.defaultImageRegistry .Values.defaultSlaveImage.registry) .Values.jenkinsSlaveImage.registry }}
{{- end }}

{{- define "jenkinsSlaveImage.path" -}}
{{- printf "%s:%s" (default .Values.defaultSlaveImage.path .Values.jenkinsSlaveImage.path) (default .Values.defaultSlaveImage.tag .Values.jenkinsSlaveImage.tag) }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "jenkins.labels" -}}
app: {{ include "jenkins.fullname" . }}
release-name: {{ .Release.Name }}
helm.sh/chart: {{ include "jenkins.chart" . }}
{{ include "jenkins.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | trunc 63 | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "jenkins.selectorLabels" -}}
name: {{ include "jenkins.fullname" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "jenkins.serviceAccountName" -}}
{{- default (include "jenkins.fullname" .) .Values.serviceAccount.name }}
{{- end }}

{{/*
Create the host of the Jenkins route
Users can specify their own route.host or route.subDomain values, otherwise a default host is generated for the route.
Specifying host takes precedence over subDomain and requires the user to specify the complete host value.
Specifying subDomain will generate a host value of the form <subDomain>.<domain>. 
  E.g If the user provides route.subDomain: myJenkins
    the following route host will be generated (when domain is cs2-dev): myJenkins.apps.cs2-dev.nz.service.test
See route-test.yaml unit test for usage examples.
*/}}
{{- define "jenkins.routeHost" -}}
  {{- if .Values.route }}
    {{- if .Values.route.host }}
      {{- tpl .Values.route.host . }}
    {{- else if .Values.route.subDomain }}
      {{- printf "%s.%s" (tpl .Values.route.subDomain $) .Values.domain }}
    {{- end }}
  {{- else }}
    {{- printf "%s-%s.%s" (include "jenkins.fullname" .) .Release.Namespace .Values.domain }}
  {{- end }}
{{- end }}

{{/*
Create the name of the JNLP service
*/}}
{{- define "jenkins.jnlpServiceName" -}}
{{- printf "%s-jnlp" (include "jenkins.fullname" .) }}
{{- end }}

{{/*
Standard port for JNLP service
*/}}
{{- define "jenkins.jnlpPort" -}}
50000
{{- end }}

{{/*
Create the name of the utils config map
*/}}
{{- define "jenkins.utilsConfigMapName" -}}
{{- printf "%s-utils" (include "jenkins.fullname" .) }}
{{- end }}

{{/*
Create the mount path of the utils config map
*/}}
{{- define "jenkins.utilsMountPath" -}}
/var/lib/jenkins-utils
{{- end }}

{{/*
Create the name of the JCasC config map
*/}}
{{- define "jenkins.jcascConfigMapName" -}}
{{- printf "%s-jcasc" (include "jenkins.fullname" .) }}
{{- end }}

{{/*
Create the mount path of the JCasC config map
*/}}
{{- define "jenkins.jcascMountPath" -}}
/var/lib/jenkins-jcasc
{{- end }}

{{/*
Generate a deterministic reload token
*/}}
{{- define "jenkins.jcascReloadToken" -}}
{{ sha256sum .Release.Name }}
{{- end }}

{{/*
Name of the config map that mounts files to the SSH folder
*/}}
{{- define "jenkins.sshConfigMapName" -}}
{{- printf "%s-ssh" (include "jenkins.fullname" .) }}
{{- end }}

{{/*
Mount path for the SSH folder used by Jenkins and the OS
*/}}
{{- define "jenkins.sshMountPath" -}}
/var/lib/jenkins/.ssh
{{- end }}