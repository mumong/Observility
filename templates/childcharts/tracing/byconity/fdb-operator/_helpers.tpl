{{/*
Default child chart values merged with tracing.byconity.fdb-operator.
*/}}
{{- define "childcharts.tracing.byconity.fdb-operator.defaults" -}}
{{- .Files.Get "files/childcharts/tracing/byconity/fdb-operator/values.yaml" -}}
{{- end -}}

{{- define "childcharts.tracing.byconity.fdb-operator.values" -}}
{{- if and .Values (hasKey .Values "tracing") -}}
{{- $defaults := include "childcharts.tracing.byconity.fdb-operator.defaults" . | fromYaml -}}
{{- $byconityValues := include "childcharts.tracing.byconity.values" . | fromYaml -}}
{{- $userValues := index $byconityValues "fdb-operator" | default dict -}}
{{- toYaml (mustMergeOverwrite (deepCopy $defaults) $userValues) -}}
{{- else -}}
{{- toYaml .Values -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "childcharts.tracing.byconity.fdb-operator.name" -}}
{{- $values := include "childcharts.tracing.byconity.fdb-operator.values" . | fromYaml -}}
{{- default "fdb-operator" $values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "childcharts.tracing.byconity.fdb-operator.fullname" -}}
{{- $values := include "childcharts.tracing.byconity.fdb-operator.values" . | fromYaml -}}
{{- if $values.fullnameOverride -}}
{{- $values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "fdb-operator" $values.nameOverride -}}
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
{{- define "childcharts.tracing.byconity.fdb-operator.chart" -}}
{{- printf "%s-%s" "fdb-operator" "1.9.0" | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "childcharts.tracing.byconity.fdb-operator.labels" -}}
{{- $values := include "childcharts.tracing.byconity.fdb-operator.values" . | fromYaml -}}
helm.sh/chart: {{ include "childcharts.tracing.byconity.fdb-operator.chart" . }}
{{ include "childcharts.tracing.byconity.fdb-operator.selectorLabels" . }}
app.kubernetes.io/version: {{ $values.image.tag | trimPrefix "v" | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "childcharts.tracing.byconity.fdb-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "childcharts.tracing.byconity.fdb-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account
*/}}
{{- define "childcharts.tracing.byconity.fdb-operator.serviceAccountName" -}}
{{- $values := include "childcharts.tracing.byconity.fdb-operator.values" . | fromYaml -}}
{{- $serviceAccount := get $values "serviceAccount" | default dict -}}
{{- if get $serviceAccount "create" -}}
    {{ default (include "childcharts.tracing.byconity.fdb-operator.fullname" .) (get $serviceAccount "name") }}
{{- else -}}
    {{ default "default" (get $serviceAccount "name") }}
{{- end -}}
{{- end -}}
