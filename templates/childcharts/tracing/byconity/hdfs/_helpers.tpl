{{/* vim: set filetype=mustache: */}}
{{/*
Default child chart values merged with tracing.byconity.hdfs.
*/}}
{{- define "childcharts.tracing.byconity.hdfs.defaults" -}}
{{- .Files.Get "files/childcharts/tracing/byconity/hdfs/values.yaml" -}}
{{- end -}}

{{- define "childcharts.tracing.byconity.hdfs.values" -}}
{{- if and .Values (hasKey .Values "tracing") -}}
{{- $defaults := include "childcharts.tracing.byconity.hdfs.defaults" . | fromYaml -}}
{{- $byconityValues := include "childcharts.tracing.byconity.values" . | fromYaml -}}
{{- $userValues := index $byconityValues "hdfs" | default dict -}}
{{- toYaml (mustMergeOverwrite (deepCopy $defaults) $userValues) -}}
{{- else -}}
{{- toYaml .Values -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "childcharts.tracing.byconity.hdfs.name" -}}
{{- $values := include "childcharts.tracing.byconity.hdfs.values" . | fromYaml -}}
{{- default "hdfs" $values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "childcharts.tracing.byconity.hdfs.fullname" -}}
{{- $values := include "childcharts.tracing.byconity.hdfs.values" . | fromYaml -}}
{{- if $values.fullnameOverride -}}
{{- $values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "hdfs" $values.nameOverride -}}
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
{{- define "childcharts.tracing.byconity.hdfs.chart" -}}
{{- printf "%s-%s" "hdfs" "1.1.0" | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "childcharts.tracing.byconity.hdfs.labels" -}}
{{- $values := include "childcharts.tracing.byconity.hdfs.values" . | fromYaml -}}
helm.sh/chart: {{ include "childcharts.tracing.byconity.hdfs.chart" . }}
{{ include "childcharts.tracing.byconity.hdfs.selectorLabels" . }}
app.kubernetes.io/version: "1.1.0"
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if $values.labels }}
{{ toYaml $values.labels }}
{{- end -}}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "childcharts.tracing.byconity.hdfs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "childcharts.tracing.byconity.hdfs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "childcharts.tracing.byconity.hdfs.namenode.volumes" -}}
{{- $count := int . -}}
{{- range $k, $v := until $count -}}
{{- if gt $v 0 -}},{{- end -}}
/data{{- $v -}}/dfs/name
{{- end -}}
{{- end -}}

{{- define "childcharts.tracing.byconity.hdfs.datanode.volumes" -}}
{{- $count := int . -}}
{{- range $k, $v := until $count -}}
{{- if gt $v 0 -}},{{- end -}}
/data{{- $v -}}/dfs/data
{{- end -}}
{{- end -}}

{{- define "childcharts.tracing.byconity.hdfs.namenodeServiceAccountName" -}}
{{- $values := include "childcharts.tracing.byconity.hdfs.values" . | fromYaml -}}
{{- $config := get $values "config" | default dict -}}
{{- $rackAwareness := get $config "rackAwareness" | default dict -}}
{{- default (printf "%s-namenode" (include "childcharts.tracing.byconity.hdfs.fullname" .)) (get $rackAwareness "serviceAccountName") -}}
{{- end -}}
