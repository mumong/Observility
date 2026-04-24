{{/* affinity - https://kubernetes.io/docs/concepts/configuration/assign-pod-node/ */}}

{{- define "childcharts.tracing.mysql.nodeaffinity" }}
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    {{- include "childcharts.tracing.mysql.nodeAffinityRequiredDuringScheduling" . }}
    preferredDuringSchedulingIgnoredDuringExecution:
    {{- include "childcharts.tracing.mysql.nodeAffinityPreferredDuringScheduling" . }}
{{- end }}

{{- define "childcharts.tracing.mysql.nodeAffinityRequiredDuringScheduling" }}
    {{- if or .Values.nodeAffinityLabelSelector .Values.global.nodeAffinityLabelSelector }}
      nodeSelectorTerms:
      {{- range $matchExpressionsItem := .Values.nodeAffinityLabelSelector }}
        - matchExpressions:
        {{- range $item := $matchExpressionsItem.matchExpressions }}
          - key: {{ $item.key }}
            operator: {{ $item.operator }}
            {{- if $item.values }}
            values:
            {{- $vals := split "," $item.values }}
            {{- range $v := $vals }}
            - {{ $v | quote }}
            {{- end }}
            {{- end }}
          {{- end }}
      {{- end }}
      {{- range $matchExpressionsItem := .Values.global.nodeAffinityLabelSelector }}
        - matchExpressions:
        {{- range $item := $matchExpressionsItem.matchExpressions }}
          - key: {{ $item.key }}
            operator: {{ $item.operator }}
            {{- if $item.values }}
            values:
            {{- $vals := split "," $item.values }}
            {{- range $v := $vals }}
            - {{ $v | quote }}
            {{- end }}
            {{- end }}
          {{- end }}
      {{- end }}
    {{- end }}
{{- end }}

{{- define "childcharts.tracing.mysql.nodeAffinityPreferredDuringScheduling" }}
    {{- range $weightItem := .Values.nodeAffinityTermLabelSelector }}
    - weight: {{ $weightItem.weight }}
      preference:
        matchExpressions:
      {{- range $item := $weightItem.matchExpressions }}
        - key: {{ $item.key }}
          operator: {{ $item.operator }}
          {{- if $item.values }}
          values:
          {{- $vals := split "," $item.values }}
          {{- range $v := $vals }}
          - {{ $v | quote }}
          {{- end }}
          {{- end }}
      {{- end }}
    {{- end }}
    {{- range $weightItem := .Values.global.nodeAffinityTermLabelSelector }}
    - weight: {{ $weightItem.weight }}
      preference:
        matchExpressions:
      {{- range $item := $weightItem.matchExpressions }}
        - key: {{ $item.key }}
          operator: {{ $item.operator }}
          {{- if $item.values }}
          values:
          {{- $vals := split "," $item.values }}
          {{- range $v := $vals }}
          - {{ $v | quote }}
          {{- end }}
          {{- end }}
      {{- end }}
    {{- end }}
{{- end }}

{{- define "childcharts.tracing.mysql.podAffinity" }}
{{- if or .Values.podAffinityLabelSelector .Values.podAffinityTermLabelSelector }}
  podAffinity:
    {{- if .Values.podAffinityLabelSelector }}
    requiredDuringSchedulingIgnoredDuringExecution:
    {{- include "childcharts.tracing.mysql.podAffinityRequiredDuringScheduling" . }}
    {{- end }}
    {{- if .Values.podAffinityTermLabelSelector }}
    preferredDuringSchedulingIgnoredDuringExecution:
    {{- include "childcharts.tracing.mysql.podAffinityPreferredDuringScheduling" . }}
    {{- end }}
{{- end }}
{{- end }}

{{- define "childcharts.tracing.mysql.podAffinityRequiredDuringScheduling" }}
    {{- range $labelSelectorItem := .Values.podAffinityLabelSelector }}
    - labelSelector:
        matchExpressions:
      {{- range $item := $labelSelectorItem.labelSelector }}
        - key: {{ $item.key }}
          operator: {{ $item.operator }}
          {{- if $item.values }}
          values:
          {{- $vals := split "," $item.values }}
          {{- range $v := $vals }}
          - {{ $v | quote }}
          {{- end }}
          {{- end }}
      {{- end }}
      topologyKey: {{ $labelSelectorItem.topologyKey }}
    {{- end }}
    {{- range $labelSelectorItem := .Values.global.podAffinityLabelSelector }}
    - labelSelector:
        matchExpressions:
      {{- range $item := $labelSelectorItem.labelSelector }}
        - key: {{ $item.key }}
          operator: {{ $item.operator }}
          {{- if $item.values }}
          values:
          {{- $vals := split "," $item.values }}
          {{- range $v := $vals }}
          - {{ $v | quote }}
          {{- end }}
          {{- end }}
      {{- end }}
      topologyKey: {{ $labelSelectorItem.topologyKey }}
    {{- end }}
{{- end }}

{{- define "childcharts.tracing.mysql.podAffinityPreferredDuringScheduling" }}
    {{- range $labelSelectorItem := .Values.podAffinityTermLabelSelector }}
    - podAffinityTerm:
        labelSelector:
          matchExpressions:
      {{- range $item := $labelSelectorItem.labelSelector }}
          - key: {{ $item.key }}
            operator: {{ $item.operator }}
            {{- if $item.values }}
            values:
            {{- $vals := split "," $item.values }}
            {{- range $v := $vals }}
            - {{ $v | quote }}
            {{- end }}
            {{- end }}
      {{- end }}
        topologyKey: {{ $labelSelectorItem.topologyKey }}
      weight: {{ $labelSelectorItem.weight }}
    {{- end }}
    {{- range $labelSelectorItem := .Values.global.podAffinityTermLabelSelector }}
    - podAffinityTerm:
        labelSelector:
          matchExpressions:
      {{- range $item := $labelSelectorItem.labelSelector }}
          - key: {{ $item.key }}
            operator: {{ $item.operator }}
            {{- if $item.values }}
            values:
            {{- $vals := split "," $item.values }}
            {{- range $v := $vals }}
            - {{ $v | quote }}
            {{- end }}
            {{- end }}
      {{- end }}
        topologyKey: {{ $labelSelectorItem.topologyKey }}
      weight: {{ $labelSelectorItem.weight }}
    {{- end }}
{{- end }}

{{- define "childcharts.tracing.mysql.podAntiAffinity" }}
{{- if or .Values.podAntiAffinityLabelSelector .Values.podAntiAffinityTermLabelSelector }}
  podAntiAffinity:
    {{- if .Values.podAntiAffinityLabelSelector }}
    requiredDuringSchedulingIgnoredDuringExecution:
    {{- include "childcharts.tracing.mysql.podAntiAffinityRequiredDuringScheduling" . }}
    {{- end }}
    {{- if .Values.podAntiAffinityTermLabelSelector }}
    preferredDuringSchedulingIgnoredDuringExecution:
    {{- include "childcharts.tracing.mysql.podAntiAffinityPreferredDuringScheduling" . }}
    {{- end }}
{{- end }}
{{- end }}

{{- define "childcharts.tracing.mysql.podAntiAffinityRequiredDuringScheduling" }}
    {{- range $labelSelectorItem := .Values.podAntiAffinityLabelSelector }}
    - labelSelector:
        matchExpressions:
      {{- range $item := $labelSelectorItem.labelSelector }}
        - key: {{ $item.key }}
          operator: {{ $item.operator }}
          {{- if $item.values }}
          values:
          {{- $vals := split "," $item.values }}
          {{- range $v := $vals }}
          - {{ $v | quote }}
          {{- end }}
          {{- end }}
      {{- end }}
      topologyKey: {{ $labelSelectorItem.topologyKey }}
    {{- end }}
    {{- range $labelSelectorItem := .Values.global.podAntiAffinityLabelSelector }}
    - labelSelector:
        matchExpressions:
      {{- range $item := $labelSelectorItem.labelSelector }}
        - key: {{ $item.key }}
          operator: {{ $item.operator }}
          {{- if $item.values }}
          values:
          {{- $vals := split "," $item.values }}
          {{- range $v := $vals }}
          - {{ $v | quote }}
          {{- end }}
          {{- end }}
      {{- end }}
      topologyKey: {{ $labelSelectorItem.topologyKey }}
    {{- end }}
{{- end }}

{{- define "childcharts.tracing.mysql.podAntiAffinityPreferredDuringScheduling" }}
    {{- range $labelSelectorItem := .Values.podAntiAffinityTermLabelSelector }}
    - podAffinityTerm:
        labelSelector:
          matchExpressions:
      {{- range $item := $labelSelectorItem.labelSelector }}
          - key: {{ $item.key }}
            operator: {{ $item.operator }}
            {{- if $item.values }}
            values:
            {{- $vals := split "," $item.values }}
            {{- range $v := $vals }}
            - {{ $v | quote }}
            {{- end }}
            {{- end }}
      {{- end }}
        topologyKey: {{ $labelSelectorItem.topologyKey }}
      weight: {{ $labelSelectorItem.weight }}
    {{- end }}
    {{- range $labelSelectorItem := .Values.global.podAntiAffinityTermLabelSelector }}
    - podAffinityTerm:
        labelSelector:
          matchExpressions:
      {{- range $item := $labelSelectorItem.labelSelector }}
          - key: {{ $item.key }}
            operator: {{ $item.operator }}
            {{- if $item.values }}
            values:
            {{- $vals := split "," $item.values }}
            {{- range $v := $vals }}
            - {{ $v | quote }}
            {{- end }}
            {{- end }}
      {{- end }}
        topologyKey: {{ $labelSelectorItem.topologyKey }}
      weight: {{ $labelSelectorItem.weight }}
    {{- end }}
{{- end }}
