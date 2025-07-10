{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "kibana.name" -}}
{{- default .Chart.Name .Values.logging.kibana.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "kibana.fullname" -}}
{{- if .Values.logging.kibana.fullnameOverride -}}
{{- .Values.logging.kibana.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- if .Values.logging.kibana.nameOverride -}}
{{- printf "%s-%s" .Release.Name .Values.logging.kibana.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-kibana" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Unified name for resource naming
*/}}
{{- define "kibana.uname" -}}
{{- if .Values.logging.kibana.fullnameOverride -}}
{{ .Values.logging.kibana.fullnameOverride }}
{{- else if .Values.logging.kibana.nameOverride -}}
{{ printf "%s-%s" .Release.Name .Values.logging.kibana.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else -}}
{{ printf "%s-kibana" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "kibana.labels" -}}
app: {{ include "kibana.uname" . }}
release: {{ .Release.Name | quote }}
heritage: {{ .Release.Service }}
{{- if .Values.logging.kibana.labels }}
{{ toYaml .Values.logging.kibana.labels }}
{{- end }}
{{- end -}}

{{/*
Kibana home directory
*/}}
{{- define "kibana.home_dir" -}}
/usr/share/kibana
{{- end -}}

{{/*
Get ElasticSearch headless service name
*/}}
{{- define "kibana.elasticsearch.headlessService" -}}
{{- printf "%s-headless" (include "elasticsearch.masterService" .) -}}
{{- end -}}

{{/*
Get ElasticSearch service URL (https)
*/}}
{{- define "kibana.elasticsearch.host" -}}
{{- if .Values.logging.kibana.elasticsearchHosts -}}
{{- .Values.logging.kibana.elasticsearchHosts -}}
{{- else -}}
{{- printf "https://%s:9200" (include "kibana.elasticsearch.headlessService" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get ElasticSearch cert secret name
*/}}
{{- define "kibana.elasticsearch.certSecret" -}}
{{- .Values.logging.kibana.elasticsearchCertificateSecret | default (printf "%s-certs" (include "elasticsearch.uname" .)) -}}
{{- end -}}

{{/*
Get ElasticSearch credentials secret name
*/}}
{{- define "kibana.elasticsearch.credSecret" -}}
{{- .Values.logging.kibana.elasticsearchCredentialSecret | default (printf "%s-credentials" (include "elasticsearch.uname" .)) -}}
{{- end -}}

{{/*
Get ElasticSearch CA file name
*/}}
{{- define "kibana.elasticsearch.caFile" -}}
{{- .Values.logging.kibana.elasticsearchCertificateAuthoritiesFile | default "ca.crt" -}}
{{- end -}}
