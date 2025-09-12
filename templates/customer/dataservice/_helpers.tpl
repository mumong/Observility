{{/*
Expand the name of the chart.
*/}}
{{- define "monitoring-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "monitoring-stack.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
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
{{- define "monitoring-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "monitoring-stack.labels" -}}
helm.sh/chart: {{ include "monitoring-stack.chart" . }}
{{ include "monitoring-stack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "monitoring-stack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "monitoring-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "monitoring-stack.serviceAccountName" -}}
{{- include "monitoring-stack.fullname" . }}-dataservice
{{- end }}

{{/*
Get cluster name from telegraf config
*/}}
{{- define "monitoring-stack.clusterName" -}}
{{- .Values.customer.dataservice.telegraf.config.global_tags.cluster | default "my-cluster" }}
{{- end }}

{{/*
Generate InfluxDB URL for local service
*/}}
{{- define "monitoring-stack.influxdbURL" -}}
http://{{ include "monitoring-stack.fullname" . }}-influxdb2.{{ .Release.Namespace }}.svc.cluster.local:8086
{{- end }}

{{/*
Generate Prometheus URLs with namespace discovery
*/}}
{{- define "monitoring-stack.prometheusURLs" -}}
"http://{{ .Release.Name  }}-prometheus.{{ .Release.Namespace  }}.svc.cluster.local:9090/federate?match[]={__name__!=\"\"}"
{{- end }}

