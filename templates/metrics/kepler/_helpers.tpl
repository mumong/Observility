{{/*
Expand the name of the chart.
*/}}
{{- define "kepler.name" -}}
{{- printf "%s-%s" (default .Chart.Name .Values.metric.kepler.nameOverride) "kepler" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kepler.fullname" -}}
{{- if .Values.metric.kepler.fullnameOverride }}
{{- .Values.metric.kepler.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.metric.kepler.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kepler.chart" -}}
{{- printf "%s-%s" .Chart.Name "0.6.0"| replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kepler.labels" -}}
helm.sh/chart: {{ include "kepler.chart" . }}
{{ include "kepler.selectorLabels" . }}
app.kubernetes.io/version: "release-0.8.0"
app.kubernetes.io/managed-by: {{ .Release.Service }}
release: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kepler.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kepler.name" . }}
app.kubernetes.io/component: exporter
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kepler.serviceAccountName" -}}
{{- if .Values.metric.kepler.serviceAccount.create }}
{{- default (printf "%s-kepler" (include "kepler.fullname" .)) .Values.metric.kepler.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.metric.kepler.serviceAccount.name }}
{{- end }}
{{- end }}
