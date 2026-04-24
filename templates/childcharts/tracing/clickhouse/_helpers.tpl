{{/*
Flattened clickhouse childchart defaults merged into tracing.clickhouse.
Templates render against the original child-chart value shape.
*/}}
{{- define "childcharts.tracing.clickhouse.defaults" -}}
{{- .Files.Get "files/childcharts/tracing/clickhouse/values.yaml" -}}
{{- end -}}

{{- define "childcharts.tracing.clickhouse.values" -}}
{{- if and .Values (hasKey .Values "tracing") -}}
{{- $defaults := include "childcharts.tracing.clickhouse.defaults" . | fromYaml -}}
{{- $tracingValues := get .Values "tracing" | default dict -}}
{{- $componentValues := get $tracingValues "clickhouse" | default dict -}}
{{- $normalizedComponentValues := (toYaml $componentValues | replace "$.Values.tracing.global." "$.Values.global." | replace ".Values.tracing.global." ".Values.global." | replace "$.Values.tracing.clickhouse." "$.Values." | replace ".Values.tracing.clickhouse." ".Values.") | fromYaml -}}
{{- $defaultGlobal := get $defaults "global" | default dict -}}
{{- $parentGlobal := get $tracingValues "global" | default dict -}}
{{- $global := mustMergeOverwrite (deepCopy $defaultGlobal) $parentGlobal -}}
{{- $merged := mustMergeOverwrite (deepCopy $defaults) $normalizedComponentValues (dict "global" $global) -}}
{{- toYaml $merged -}}
{{- else -}}
{{- toYaml .Values -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "childcharts.tracing.clickhouse.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "childcharts.tracing.clickhouse.fullname" -}}
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
{{- define "childcharts.tracing.clickhouse.chart" -}}
{{- printf "%s-%s" .Chart.Name (.Chart.Version | default "0.0.0") | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "childcharts.tracing.clickhouse.labels" -}}
helm.sh/chart: {{ include "childcharts.tracing.clickhouse.chart" . }}
{{ include "childcharts.tracing.clickhouse.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "childcharts.tracing.clickhouse.storageType" -}}
{{- if .Values.global.allInOneLocalStorage -}}
hostPath
{{- else -}}
{{- .Values.storageConfig.type -}}
{{- end -}}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "childcharts.tracing.clickhouse.selectorLabels" -}}
app: deepflow
component: clickhouse
app.kubernetes.io/name: {{ include "childcharts.tracing.clickhouse.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "childcharts.tracing.clickhouse.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "childcharts.tracing.clickhouse.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
