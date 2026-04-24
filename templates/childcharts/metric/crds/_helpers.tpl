{{/*
Default child chart values merged with metric.crds.
*/}}
{{- define "childcharts.metric.crds.defaults" -}}
{{- .Files.Get "files/childcharts/metric/crds/values.yaml" -}}
{{- end -}}

{{- define "childcharts.metric.crds.values" -}}
{{- if and .Values (hasKey .Values "metric") -}}
{{- $defaults := include "childcharts.metric.crds.defaults" . | fromYaml -}}
{{- $userValues := index .Values.metric "crds" | default dict -}}
{{- toYaml (mustMergeOverwrite (deepCopy $defaults) $userValues) -}}
{{- else -}}
{{- toYaml .Values -}}
{{- end -}}
{{- end -}}

{{/* Shortened name suffixed with upgrade-crd */}}
{{- define "childcharts.metric.crds.upgradeJob.name" -}}
{{- print (include "kube-prometheus-stack.fullname" .) "-upgrade" -}}
{{- end -}}

{{- define "childcharts.metric.crds.upgradeJob.labels" -}}
{{- include "kube-prometheus-stack.labels" . }}
app: {{ template "kube-prometheus-stack.name" . }}-operator
app.kubernetes.io/name: {{ template "kube-prometheus-stack.name" . }}-prometheus-operator
app.kubernetes.io/component: crds-upgrade
{{- end -}}

{{/* Create the name of crd.upgradeJob service account to use */}}
{{- define "childcharts.metric.crds.upgradeJob.serviceAccountName" -}}
{{- if .Values.upgradeJob.serviceAccount.create -}}
    {{ default (include "childcharts.metric.crds.upgradeJob.name" .) .Values.upgradeJob.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.upgradeJob.serviceAccount.name }}
{{- end -}}
{{- end -}}
