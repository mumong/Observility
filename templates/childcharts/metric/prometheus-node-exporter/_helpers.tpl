{{/* vim: set filetype=mustache: */}}
{{/*
Default child chart values merged with metric.prometheus-node-exporter.
*/}}
{{- define "childcharts.metric.prometheus-node-exporter.defaults" -}}
{{- .Files.Get "files/childcharts/metric/prometheus-node-exporter/values.yaml" -}}
{{- end -}}

{{- define "childcharts.metric.prometheus-node-exporter.values" -}}
{{- if and .Values (hasKey .Values "metric") -}}
{{- $defaults := include "childcharts.metric.prometheus-node-exporter.defaults" . | fromYaml -}}
{{- $userValues := index .Values.metric "prometheus-node-exporter" | default dict -}}
{{- $legacyValues := get .Values.metric "nodeExporter" | default dict -}}
{{- $enabled := true -}}
{{- if hasKey $legacyValues "enabled" -}}
{{- $enabled = get $legacyValues "enabled" -}}
{{- end -}}
{{- if hasKey $userValues "enabled" -}}
{{- $enabled = get $userValues "enabled" -}}
{{- end -}}
{{- $mergedValues := mustMergeOverwrite (deepCopy $defaults) $userValues (dict "enabled" $enabled) -}}
{{- toYaml $mergedValues -}}
{{- else -}}
{{- toYaml .Values -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "childcharts.metric.prometheus-node-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "childcharts.metric.prometheus-node-exporter.fullname" -}}
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
{{- define "childcharts.metric.prometheus-node-exporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "childcharts.metric.prometheus-node-exporter.labels" -}}
helm.sh/chart: {{ include "childcharts.metric.prometheus-node-exporter.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: metrics
app.kubernetes.io/part-of: {{ include "childcharts.metric.prometheus-node-exporter.name" . }}
{{ include "childcharts.metric.prometheus-node-exporter.selectorLabels" . }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . | quote }}
{{- end }}
{{- with .Values.commonLabels }}
{{ tpl (toYaml .) $ }}
{{- end }}
{{- if .Values.releaseLabel }}
release: {{ .Release.Name }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "childcharts.metric.prometheus-node-exporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "childcharts.metric.prometheus-node-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "childcharts.metric.prometheus-node-exporter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "childcharts.metric.prometheus-node-exporter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
The image to use
*/}}
{{- define "childcharts.metric.prometheus-node-exporter.image" -}}
{{- if .Values.image.sha }}
{{- fail "image.sha forbidden. Use image.digest instead" }}
{{- else if .Values.image.digest }}
{{- if .Values.global.imageRegistry }}
{{- printf "%s/%s:%s@%s" .Values.global.imageRegistry .Values.image.repository (default (printf "v%s" .Chart.AppVersion) .Values.image.tag) .Values.image.digest }}
{{- else }}
{{- printf "%s/%s:%s@%s" .Values.image.registry .Values.image.repository (default (printf "v%s" .Chart.AppVersion) .Values.image.tag) .Values.image.digest }}
{{- end }}
{{- else }}
{{- if .Values.global.imageRegistry }}
{{- printf "%s/%s:%s" .Values.global.imageRegistry .Values.image.repository (default (printf "v%s" .Chart.AppVersion) .Values.image.tag) }}
{{- else }}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository (default (printf "v%s" .Chart.AppVersion) .Values.image.tag) }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "childcharts.metric.prometheus-node-exporter.namespace" -}}
{{- if .Values.namespaceOverride }}
{{- .Values.namespaceOverride }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Create the namespace name of the service monitor
*/}}
{{- define "childcharts.metric.prometheus-node-exporter.monitor-namespace" -}}
{{- if .Values.namespaceOverride }}
{{- .Values.namespaceOverride }}
{{- else }}
{{- if .Values.prometheus.monitor.namespace }}
{{- .Values.prometheus.monitor.namespace }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}
{{- end }}

{{/* Sets default scrape limits for servicemonitor */}}
{{- define "childcharts.metric.prometheus-node-exporter.servicemonitor.scrapeLimits" -}}
{{- with .sampleLimit }}
sampleLimit: {{ . }}
{{- end }}
{{- with .targetLimit }}
targetLimit: {{ . }}
{{- end }}
{{- with .labelLimit }}
labelLimit: {{ . }}
{{- end }}
{{- with .labelNameLengthLimit }}
labelNameLengthLimit: {{ . }}
{{- end }}
{{- with .labelValueLengthLimit }}
labelValueLengthLimit: {{ . }}
{{- end }}
{{- end }}

{{/*
Formats imagePullSecrets. Input is (dict "Values" .Values "imagePullSecrets" .{specific imagePullSecrets})
*/}}
{{- define "childcharts.metric.prometheus-node-exporter.imagePullSecrets" -}}
{{- range (concat .Values.global.imagePullSecrets .imagePullSecrets) }}
  {{- if eq (typeOf .) "map[string]interface {}" }}
- {{ toYaml . | trim }}
  {{- else }}
- name: {{ . }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Create the namespace name of the pod monitor
*/}}
{{- define "childcharts.metric.prometheus-node-exporter.podmonitor-namespace" -}}
{{- if .Values.namespaceOverride }}
{{- .Values.namespaceOverride }}
{{- else }}
{{- if .Values.prometheus.podMonitor.namespace }}
{{- .Values.prometheus.podMonitor.namespace }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}
{{- end }}

{{/* Sets default scrape limits for podmonitor */}}
{{- define "childcharts.metric.prometheus-node-exporter.podmonitor.scrapeLimits" -}}
{{- with .sampleLimit }}
sampleLimit: {{ . }}
{{- end }}
{{- with .targetLimit }}
targetLimit: {{ . }}
{{- end }}
{{- with .labelLimit }}
labelLimit: {{ . }}
{{- end }}
{{- with .labelNameLengthLimit }}
labelNameLengthLimit: {{ . }}
{{- end }}
{{- with .labelValueLengthLimit }}
labelValueLengthLimit: {{ . }}
{{- end }}
{{- end }}

{{/* Sets sidecar volumeMounts */}}
{{- define "childcharts.metric.prometheus-node-exporter.sidecarVolumeMounts" -}}
{{- range $_, $mount := $.Values.sidecarVolumeMount }}
- name: {{ $mount.name }}
  mountPath: {{ $mount.mountPath }}
  readOnly: {{ $mount.readOnly }}
{{- end }}
{{- range $_, $mount := $.Values.sidecarHostVolumeMounts }}
- name: {{ $mount.name }}
  mountPath: {{ $mount.mountPath }}
  readOnly: {{ $mount.readOnly }}
{{- if $mount.mountPropagation }}
  mountPropagation: {{ $mount.mountPropagation }}
{{- end }}
{{- end }}
{{- end }}

{{/*
The default node affinity to exclude 
- AWS Fargate 
- Azure virtual nodes
*/}}
{{- define "childcharts.metric.prometheus-node-exporter.defaultAffinity" -}}
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    - matchExpressions:
      - key: eks.amazonaws.com/compute-type
        operator: NotIn
        values:
        - fargate
      - key: type
        operator: NotIn
        values:
        - virtual-kubelet
{{- end -}}
{{- define "childcharts.metric.prometheus-node-exporter.mergedAffinities" -}}
{{- $defaultAffinity := include "childcharts.metric.prometheus-node-exporter.defaultAffinity" . | fromYaml -}}
{{- with .Values.affinity -}}
  {{- if .nodeAffinity -}}
    {{- $_ := set $defaultAffinity "nodeAffinity" (mergeOverwrite $defaultAffinity.nodeAffinity .nodeAffinity) -}}
  {{- end -}}
  {{- if .podAffinity -}}
    {{- $_ := set $defaultAffinity "podAffinity" .podAffinity -}}
  {{- end -}}
  {{- if .podAntiAffinity -}}
    {{- $_ := set $defaultAffinity "podAntiAffinity" .podAntiAffinity -}}
  {{- end -}}
{{- end -}}
{{- toYaml $defaultAffinity -}}
{{- end -}}
