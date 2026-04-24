{{/*
Expand the name of the chart.
*/}}
{{- define "childcharts.tracing.deepflow-agent.name" -}}
{{- $values := include "childcharts.tracing.deepflow-agent.values" . | fromYaml -}}
{{- default "deepflow-agent" $values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "childcharts.tracing.deepflow-agent.fullname" -}}
{{- $values := include "childcharts.tracing.deepflow-agent.values" . | fromYaml -}}
{{- $fullnameOverride := default "deepflow-agent" $values.agentFullnameOverride -}}
{{- if $fullnameOverride }}
{{- $fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "deepflow-agent" $values.nameOverride }}
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
{{- define "childcharts.tracing.deepflow-agent.chart" -}}
{{- printf "%s-%s" "deepflow-agent" "7.0.014" | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "childcharts.tracing.deepflow-agent.labels" -}}
helm.sh/chart: {{ include "childcharts.tracing.deepflow-agent.chart" . }}
{{ include "childcharts.tracing.deepflow-agent.selectorLabels" . }}
app.kubernetes.io/version: "7.0"
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "childcharts.tracing.deepflow-agent.selectorLabels" -}}
app: deepflow
component: deepflow-agent
app.kubernetes.io/name: {{ include "childcharts.tracing.deepflow-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Default child chart values merged with tracing."deepflow-agent".
*/}}
{{- define "childcharts.tracing.deepflow-agent.defaults" -}}
{{- .Files.Get "files/childcharts/tracing/deepflow-agent/values.yaml" -}}
{{- end }}

{{- define "childcharts.tracing.deepflow-agent.values" -}}
{{- $defaults := include "childcharts.tracing.deepflow-agent.defaults" . | fromYaml -}}
{{- $tracingValues := get .Values "tracing" | default dict -}}
{{- $userValues := index $tracingValues "deepflow-agent" | default dict -}}
{{- $defaultGlobal := get $defaults "global" | default dict -}}
{{- $parentGlobal := get $tracingValues "global" | default dict -}}
{{- $global := mustMergeOverwrite (deepCopy $defaultGlobal) $parentGlobal -}}
{{- toYaml (mustMergeOverwrite (deepCopy $defaults) $userValues (dict "global" $global)) -}}
{{- end }}
