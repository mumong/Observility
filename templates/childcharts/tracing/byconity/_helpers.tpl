{{/*
Default child chart values merged with tracing.byconity.
*/}}
{{- define "childcharts.tracing.byconity.defaults" -}}
{{- .Files.Get "files/childcharts/tracing/byconity/values.yaml" -}}
{{- end }}

{{- define "childcharts.tracing.byconity.values" -}}
{{- if and .Values (hasKey .Values "tracing") -}}
{{- $defaults := include "childcharts.tracing.byconity.defaults" . | fromYaml -}}
{{- $userValues := index .Values.tracing "byconity" | default dict -}}
{{- $normalizedUserValues := (toYaml $userValues | replace "$.Values.tracing.global." "$.Values.global." | replace ".Values.tracing.global." ".Values.global." | replace "$.Values.tracing.byconity." "$.Values." | replace ".Values.tracing.byconity." ".Values.") | fromYaml -}}
{{- toYaml (mustMergeOverwrite (deepCopy $defaults) $normalizedUserValues) -}}
{{- else -}}
{{- toYaml .Values -}}
{{- end -}}
{{- end }}

{{/*
Normalize a PVC spec so empty storageClassName does not disable the cluster default.
If tracing.global.storageClass is set, inherit it.
*/}}
{{- define "childcharts.tracing.byconity.pvcSpec" -}}
{{- $spec := deepCopy (.spec | default dict) -}}
{{- $global := .global | default dict -}}
{{- $storageClassName := get $spec "storageClassName" -}}
{{- $globalStorageClass := get $global "storageClass" -}}
{{- if and (empty $storageClassName) (not (empty $globalStorageClass)) -}}
{{- $_ := set $spec "storageClassName" $globalStorageClass -}}
{{- else if empty $storageClassName -}}
{{- $_ := unset $spec "storageClassName" -}}
{{- end -}}
{{- toYaml $spec -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "childcharts.tracing.byconity.name" -}}
{{- $values := include "childcharts.tracing.byconity.values" . | fromYaml -}}
{{- default "byconity" $values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "childcharts.tracing.byconity.fullname" -}}
{{- $values := include "childcharts.tracing.byconity.values" . | fromYaml -}}
{{- if $values.fullnameOverride }}
{{- $values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "byconity" $values.nameOverride }}
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
{{- define "childcharts.tracing.byconity.chart" -}}
{{- printf "%s-%s" "byconity" "0.1.0" | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "childcharts.tracing.byconity.labels" -}}
helm.sh/chart: {{ include "childcharts.tracing.byconity.chart" . }}
{{ include "childcharts.tracing.byconity.selectorLabels" . }}
app.kubernetes.io/version: "1.16.0"
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "childcharts.tracing.byconity.selectorLabels" -}}
app.kubernetes.io/name: {{ include "childcharts.tracing.byconity.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "childcharts.tracing.byconity.serviceAccountName" -}}
{{- $values := include "childcharts.tracing.byconity.values" . | fromYaml -}}
{{- $serviceAccount := get $values "serviceAccount" | default dict -}}
{{- if get $serviceAccount "create" }}
{{- default (include "childcharts.tracing.byconity.fullname" .) (get $serviceAccount "name") }}
{{- else }}
{{- default "default" (get $serviceAccount "name") }}
{{- end }}
{{- end }}

{{/*
Create common environment variables to use
*/}}
{{- define "childcharts.tracing.byconity.commonEnvs" -}}
- name: MY_POD_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: "metadata.namespace"
- name: MY_POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: "metadata.name"
- name: MY_UID
  valueFrom:
    fieldRef:
      apiVersion: v1
      fieldPath: "metadata.uid"
- name: MY_POD_IP
  valueFrom:
    fieldRef:
      fieldPath: "status.podIP"
- name: MY_HOST_IP
  valueFrom:
    fieldRef:
      fieldPath: "status.hostIP"
{{- end }}
