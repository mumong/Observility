{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "filebeat.name" -}}
{{- default .Chart.Name .Values.logging.filebeat.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "filebeat.fullname" -}}
{{- if .Values.logging.filebeat.fullnameOverride -}}
{{- .Values.logging.filebeat.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- if .Values.logging.filebeat.nameOverride -}}
{{- printf "%s-%s" .Release.Name .Values.logging.filebeat.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-filebeat" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Unified name for resource naming
*/}}
{{- define "filebeat.uname" -}}
{{- if .Values.logging.filebeat.fullnameOverride -}}
{{ .Values.logging.filebeat.fullnameOverride }}
{{- else if .Values.logging.filebeat.nameOverride -}}
{{ printf "%s-%s" .Release.Name .Values.logging.filebeat.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else -}}
{{ printf "%s-filebeat" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "filebeat.labels" -}}
app: {{ include "filebeat.uname" . }}
release: {{ .Release.Name | quote }}
heritage: {{ .Release.Service }}
{{- if .Values.logging.filebeat.labels }}
{{ toYaml .Values.logging.filebeat.labels }}
{{- end }}
{{- end -}}

{{/*
Use the fullname if the serviceAccount value is not set
*/}}
{{- define "filebeat.serviceAccount" -}}
{{- if .Values.logging.filebeat.serviceAccount }}
{{- .Values.logging.filebeat.serviceAccount -}}
{{- else }}
{{- $name := default .Chart.Name .Values.logging.filebeat.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Get ElasticSearch headless service name
*/}}
{{- define "filebeat.elasticsearch.headlessService" -}}
{{- if .Values.logging.filebeat.elasticsearchHeadlessService -}}
{{- .Values.logging.filebeat.elasticsearchHeadlessService -}}
{{- else -}}
{{- printf "%s-headless" (include "elasticsearch.masterService" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get ElasticSearch service URL (https)
*/}}
{{- define "filebeat.elasticsearch.host" -}}
{{- if .Values.logging.filebeat.elasticsearchHosts -}}
{{- .Values.logging.filebeat.elasticsearchHosts -}}
{{- else -}}
{{- printf "https://%s:9200" (include "filebeat.elasticsearch.headlessService" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get ElasticSearch cert secret name
*/}}
{{- define "filebeat.elasticsearch.certSecret" -}}
{{- .Values.logging.filebeat.elasticsearchCertificateSecret | default (printf "%s-certs" (include "elasticsearch.uname" .)) -}}
{{- end -}}

{{/*
Get ElasticSearch credentials secret name
*/}}
{{- define "filebeat.elasticsearch.credSecret" -}}
{{- .Values.logging.filebeat.elasticsearchCredentialSecret | default (printf "%s-credentials" (include "elasticsearch.uname" .)) -}}
{{- end -}}

{{/*
Get ElasticSearch CA file name
*/}}
{{- define "filebeat.elasticsearch.caFile" -}}
{{- .Values.logging.filebeat.elasticsearchCertificateAuthoritiesFile | default "ca.crt" -}}
{{- end -}}
