{{/*
Expand the name of the chart.
*/}}
{{- define "childcharts.tracing.stella-agent-ce.name" -}}
{{- $values := include "childcharts.tracing.stella-agent-ce.values" . | fromYaml -}}
{{- default "stella-agent-ce" $values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "childcharts.tracing.stella-agent-ce.fullname" -}}
{{- $values := include "childcharts.tracing.stella-agent-ce.values" . | fromYaml -}}
{{- if $values.fullnameOverride }}
{{- $values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "stella-agent-ce" $values.nameOverride }}
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
{{- define "childcharts.tracing.stella-agent-ce.chart" -}}
{{- printf "%s-%s" "stella-agent-ce" "6.5.001" | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "childcharts.tracing.stella-agent-ce.labels" -}}
helm.sh/chart: {{ include "childcharts.tracing.stella-agent-ce.chart" . }}
{{ include "childcharts.tracing.stella-agent-ce.selectorLabels" . }}
app.kubernetes.io/version: "6.5.0"
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "childcharts.tracing.stella-agent-ce.selectorLabels" -}}
app: deepflow
component: stella-agent-ce
app.kubernetes.io/name: {{ include "childcharts.tracing.stella-agent-ce.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Default child chart values merged with tracing."stella-agent-ce".
*/}}
{{- define "childcharts.tracing.stella-agent-ce.defaults" -}}
{{- .Files.Get "files/childcharts/tracing/stella-agent-ce/values.yaml" -}}
{{- end }}

{{- define "childcharts.tracing.stella-agent-ce.values" -}}
{{- $defaults := include "childcharts.tracing.stella-agent-ce.defaults" . | fromYaml -}}
{{- $tracingValues := get .Values "tracing" | default dict -}}
{{- $userValues := index $tracingValues "stella-agent-ce" | default dict -}}
{{- $defaultGlobal := get $defaults "global" | default dict -}}
{{- $parentGlobal := get $tracingValues "global" | default dict -}}
{{- $global := mustMergeOverwrite (deepCopy $defaultGlobal) $parentGlobal -}}
{{- toYaml (mustMergeOverwrite (deepCopy $defaults) $userValues (dict "global" $global)) -}}
{{- end }}
