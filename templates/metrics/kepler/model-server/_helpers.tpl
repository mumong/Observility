{{- define "modelServer.name" -}}
{{- default "model-server" .Values.metric.kepler.modelServer.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "modelServer.fullname" -}}
{{- if .Values.metric.kepler.modelServer.fullnameOverride }}
{{- .Values.metric.kepler.modelServer.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "model-server" .Values.metric.kepler.modelServer.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "modelServer.labels" -}}
helm.sh/chart: {{ include "kepler.chart" . }}
{{ include "modelServer.selectorLabels" . }}
app.kubernetes.io/version: "release-0.8.0"
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "modelServer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kepler.name" . }}
app.kubernetes.io/component: model-server
{{- end }}
