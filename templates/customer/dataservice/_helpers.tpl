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
{{- if .Values.customer.dataservice.serviceAccount.create }}
{{- default (include "monitoring-stack.fullname" .) .Values.customer.dataservice.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.customer.dataservice.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get cluster name with auto-detection
*/}}
{{- define "monitoring-stack.clusterName" -}}
{{- if .Values.customer.dataservice.global.clusterName }}
{{- .Values.customer.dataservice.global.clusterName }}
{{- else if .Values.customer.dataservice.global.xnetAgent.autoDetectCluster }}
{{- .Values.customer.dataservice.global.xnetAgent.fallbackClusterName }}
{{- else }}
{{- .Values.customer.dataservice.global.xnetAgent.fallbackClusterName }}
{{- end }}
{{- end }}

{{/*
Generate InfluxDB URL with service discovery
*/}}
{{- define "monitoring-stack.influxdbURL" -}}
http://{{ .Values.customer.dataservice.global.xnetAgent.managementService.name }}.{{ .Values.customer.dataservice.global.xnetAgent.serviceNamespace }}.svc.cluster.local:{{ .Values.customer.dataservice.global.xnetAgent.managementService.port }}
{{- end }}

{{/*
Generate Prometheus URLs with namespace discovery
*/}}
{{- define "monitoring-stack.prometheusURLs" -}}
"http://{{ .Release.Name  }}-observability-prometheus.{{ .Release.Namespace  }}.svc.cluster.local:9090/federate?match[]={__name__!=\"\"}"
{{- end }}