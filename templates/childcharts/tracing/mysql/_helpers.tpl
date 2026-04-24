{{/*
Flattened mysql childchart helpers with merged defaults.
*/}}

{{- define "childcharts.tracing.mysql.defaults" -}}
{{- .Files.Get "files/childcharts/tracing/mysql/values.yaml" -}}
{{- end -}}

{{- define "childcharts.tracing.mysql.values" -}}
{{- if and .Values (hasKey .Values "tracing") -}}
{{- $defaults := include "childcharts.tracing.mysql.defaults" . | fromYaml -}}
{{- $tracingValues := get .Values "tracing" | default dict -}}
{{- $componentValues := get $tracingValues "mysql" | default dict -}}
{{- $normalizedComponentValues := (toYaml $componentValues | replace "$.Values.tracing.global." "$.Values.global." | replace ".Values.tracing.global." ".Values.global." | replace "$.Values.tracing.mysql." "$.Values." | replace ".Values.tracing.mysql." ".Values.") | fromYaml -}}
{{- $defaultGlobal := get $defaults "global" | default dict -}}
{{- $parentGlobal := get $tracingValues "global" | default dict -}}
{{- $global := mustMergeOverwrite (deepCopy $defaultGlobal) $parentGlobal -}}
{{- $externalMySQL := get $parentGlobal "externalMySQL" | default ((get $defaults "externalMySQL") | default dict) -}}
{{- $merged := mustMergeOverwrite (deepCopy $defaults) $normalizedComponentValues (dict "global" $global "externalMySQL" $externalMySQL) -}}
{{- toYaml $merged -}}
{{- else -}}
{{- toYaml .Values -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "childcharts.tracing.mysql.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "childcharts.tracing.mysql.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "childcharts.tracing.mysql.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "childcharts.tracing.mysql.labels" -}}
helm.sh/chart: {{ include "childcharts.tracing.mysql.chart" . }}
{{ include "childcharts.tracing.mysql.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "childcharts.tracing.mysql.selectorLabels" -}}
app: deepflow
component: mysql
app.kubernetes.io/name: {{ include "childcharts.tracing.mysql.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
