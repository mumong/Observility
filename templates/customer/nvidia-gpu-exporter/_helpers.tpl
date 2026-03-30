{{/*
nvidia-gpu-exporter fullname
*/}}
{{- define "nvidia-gpu-exporter.fullname" -}}
{{ include "monitoring-stack.fullname" . }}-nvidia-gpu-exporter
{{- end }}

{{/*
nvidia-gpu-exporter labels
*/}}
{{- define "nvidia-gpu-exporter.labels" -}}
{{ include "monitoring-stack.labels" . }}
app.kubernetes.io/component: nvidia-gpu-exporter
{{- end }}

{{/*
nvidia-gpu-exporter selector labels
*/}}
{{- define "nvidia-gpu-exporter.selectorLabels" -}}
{{ include "monitoring-stack.selectorLabels" . }}
app.kubernetes.io/component: nvidia-gpu-exporter
{{- end }}

{{/*
nvidia-gpu-exporter service account name
*/}}
{{- define "nvidia-gpu-exporter.serviceAccountName" -}}
{{- if .Values.customer.nvidiaGpuExporter.serviceAccount.create }}
{{- default (include "nvidia-gpu-exporter.fullname" .) .Values.customer.nvidiaGpuExporter.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.customer.nvidiaGpuExporter.serviceAccount.name }}
{{- end }}
{{- end }}
