{{/* affinity - https://kubernetes.io/docs/concepts/configuration/assign-pod-node/ */}}

{{- define "childcharts.tracing.stella-agent-ce.nodeaffinity" }}
{{- $values := include "childcharts.tracing.stella-agent-ce.values" . | fromYaml -}}
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    {{- include "childcharts.tracing.stella-agent-ce.nodeAffinityRequiredDuringScheduling" (dict "root" . "values" $values) }}
    preferredDuringSchedulingIgnoredDuringExecution:
    {{- include "childcharts.tracing.stella-agent-ce.nodeAffinityPreferredDuringScheduling" (dict "root" . "values" $values) }}
{{- end }}

{{- define "childcharts.tracing.stella-agent-ce.nodeAffinityRequiredDuringScheduling" }}
    {{- if or .values.nodeAffinityLabelSelector .values.global.nodeAffinityLabelSelector }}
      nodeSelectorTerms:
      {{- range $matchExpressionsIndex, $matchExpressionsItem := .values.nodeAffinityLabelSelector }}
        - matchExpressions:
        {{- range $Index, $item := $matchExpressionsItem.matchExpressions }}
          - key: {{ $item.key }}
            operator: {{ $item.operator }}
            {{- if $item.values }}
            values:
            {{- $vals := split "," $item.values }}
            {{- range $i, $v := $vals }}
            - {{ $v | quote }}
            {{- end }}
            {{- end }}
          {{- end }}
      {{- end }}
      {{- range $matchExpressionsIndex, $matchExpressionsItem := .values.global.nodeAffinityLabelSelector }}
        - matchExpressions:
        {{- range $Index, $item := $matchExpressionsItem.matchExpressions }}
          - key: {{ $item.key }}
            operator: {{ $item.operator }}
            {{- if $item.values }}
            values:
            {{- $vals := split "," $item.values }}
            {{- range $i, $v := $vals }}
            - {{ $v | quote }}
            {{- end }}
            {{- end }}
          {{- end }}
      {{- end }}
    {{- end }}
{{- end }}

{{- define "childcharts.tracing.stella-agent-ce.nodeAffinityPreferredDuringScheduling" }}
    {{- range $weightIndex, $weightItem := .values.nodeAffinityTermLabelSelector }}
    - weight: {{ $weightItem.weight }}
      preference:
        matchExpressions:
      {{- range $Index, $item := $weightItem.matchExpressions }}
        - key: {{ $item.key }}
          operator: {{ $item.operator }}
          {{- if $item.values }}
          values:
          {{- $vals := split "," $item.values }}
          {{- range $i, $v := $vals }}
          - {{ $v | quote }}
          {{- end }}
          {{- end }}
      {{- end }}
    {{- end }}
    {{- range $weightIndex, $weightItem := .values.global.nodeAffinityTermLabelSelector }}
    - weight: {{ $weightItem.weight }}
      preference:
        matchExpressions:
      {{- range $Index, $item := $weightItem.matchExpressions }}
        - key: {{ $item.key }}
          operator: {{ $item.operator }}
          {{- if $item.values }}
          values:
          {{- $vals := split "," $item.values }}
          {{- range $i, $v := $vals }}
          - {{ $v | quote }}
          {{- end }}
          {{- end }}
      {{- end }}
    {{- end }}
{{- end }}

{{- define "childcharts.tracing.stella-agent-ce.podAffinity" }}
{{- $values := include "childcharts.tracing.stella-agent-ce.values" . | fromYaml -}}
{{- if or $values.podAffinityLabelSelector $values.podAffinityTermLabelSelector }}
  podAffinity:
    {{- if $values.podAffinityLabelSelector }}
    requiredDuringSchedulingIgnoredDuringExecution:
    {{- include "childcharts.tracing.stella-agent-ce.podAffinityRequiredDuringScheduling" (dict "root" . "values" $values) }}
    {{- end }}
    {{- if $values.podAffinityTermLabelSelector }}
    preferredDuringSchedulingIgnoredDuringExecution:
    {{- include "childcharts.tracing.stella-agent-ce.podAffinityPreferredDuringScheduling" (dict "root" . "values" $values) }}
    {{- end }}
{{- end }}
{{- end }}

{{- define "childcharts.tracing.stella-agent-ce.podAffinityRequiredDuringScheduling" }}
    {{- range $labelSelector, $labelSelectorItem := .values.podAffinityLabelSelector }}
    - labelSelector:
        matchExpressions:
      {{- range $index, $item := $labelSelectorItem.labelSelector }}
        - key: {{ $item.key }}
          operator: {{ $item.operator }}
          {{- if $item.values }}
          values:
          {{- $vals := split "," $item.values }}
          {{- range $i, $v := $vals }}
          - {{ $v | quote }}
          {{- end }}
          {{- end }}
        {{- end }}
      topologyKey: {{ $labelSelectorItem.topologyKey }}
    {{- end }}
    {{- range $labelSelector, $labelSelectorItem := .values.global.podAffinityLabelSelector }}
    - labelSelector:
        matchExpressions:
      {{- range $index, $item := $labelSelectorItem.labelSelector }}
        - key: {{ $item.key }}
          operator: {{ $item.operator }}
          {{- if $item.values }}
          values:
          {{- $vals := split "," $item.values }}
          {{- range $i, $v := $vals }}
          - {{ $v | quote }}
          {{- end }}
          {{- end }}
        {{- end }}
      topologyKey: {{ $labelSelectorItem.topologyKey }}
    {{- end }}
{{- end }}

{{- define "childcharts.tracing.stella-agent-ce.podAffinityPreferredDuringScheduling" }}
    {{- range $labelSelector, $labelSelectorItem := .values.podAffinityTermLabelSelector }}
    - podAffinityTerm:
        labelSelector:
          matchExpressions:
      {{- range $index, $item := $labelSelectorItem.labelSelector }}
          - key: {{ $item.key }}
            operator: {{ $item.operator }}
            {{- if $item.values }}
            values:
            {{- $vals := split "," $item.values }}
            {{- range $i, $v := $vals }}
            - {{ $v | quote }}
            {{- end }}
            {{- end }}
        {{- end }}
        topologyKey: {{ $labelSelectorItem.topologyKey }}
      weight: {{ $labelSelectorItem.weight }}
    {{- end }}
    {{- range $labelSelector, $labelSelectorItem := .values.global.podAffinityTermLabelSelector }}
    - podAffinityTerm:
        labelSelector:
          matchExpressions:
      {{- range $index, $item := $labelSelectorItem.labelSelector }}
          - key: {{ $item.key }}
            operator: {{ $item.operator }}
            {{- if $item.values }}
            values:
            {{- $vals := split "," $item.values }}
            {{- range $i, $v := $vals }}
            - {{ $v | quote }}
            {{- end }}
            {{- end }}
        {{- end }}
        topologyKey: {{ $labelSelectorItem.topologyKey }}
      weight: {{ $labelSelectorItem.weight }}
    {{- end }}
{{- end }}

{{- define "childcharts.tracing.stella-agent-ce.podAntiAffinity" }}
{{- $values := include "childcharts.tracing.stella-agent-ce.values" . | fromYaml -}}
{{- if or $values.podAntiAffinityLabelSelector $values.podAntiAffinityTermLabelSelector }}
  podAntiAffinity:
    {{- if $values.podAntiAffinityLabelSelector }}
    requiredDuringSchedulingIgnoredDuringExecution:
    {{- include "childcharts.tracing.stella-agent-ce.podAntiAffinityRequiredDuringScheduling" (dict "root" . "values" $values) }}
    {{- end }}
    {{- if $values.podAntiAffinityTermLabelSelector }}
    preferredDuringSchedulingIgnoredDuringExecution:
    {{- include "childcharts.tracing.stella-agent-ce.podAntiAffinityPreferredDuringScheduling" (dict "root" . "values" $values) }}
    {{- end }}
{{- end }}
{{- end }}

{{- define "childcharts.tracing.stella-agent-ce.podAntiAffinityRequiredDuringScheduling" }}
    {{- range $labelSelectorIndex, $labelSelectorItem := .values.podAntiAffinityLabelSelector }}
    - labelSelector:
        matchExpressions:
      {{- range $index, $item := $labelSelectorItem.labelSelector }}
        - key: {{ $item.key }}
          operator: {{ $item.operator }}
          {{- if $item.values }}
          values:
          {{- $vals := split "," $item.values }}
          {{- range $i, $v := $vals }}
          - {{ $v | quote }}
          {{- end }}
          {{- end }}
        {{- end }}
      topologyKey: {{ $labelSelectorItem.topologyKey }}
    {{- end }}
    {{- range $labelSelectorIndex, $labelSelectorItem := .values.global.podAntiAffinityLabelSelector }}
    - labelSelector:
        matchExpressions:
      {{- range $index, $item := $labelSelectorItem.labelSelector }}
        - key: {{ $item.key }}
          operator: {{ $item.operator }}
          {{- if $item.values }}
          values:
          {{- $vals := split "," $item.values }}
          {{- range $i, $v := $vals }}
          - {{ $v | quote }}
          {{- end }}
          {{- end }}
        {{- end }}
      topologyKey: {{ $labelSelectorItem.topologyKey }}
    {{- end }}
{{- end }}

{{- define "childcharts.tracing.stella-agent-ce.podAntiAffinityPreferredDuringScheduling" }}
    {{- range $labelSelectorIndex, $labelSelectorItem := .values.podAntiAffinityTermLabelSelector }}
    - podAffinityTerm:
        labelSelector:
          matchExpressions:
      {{- range $index, $item := $labelSelectorItem.labelSelector }}
          - key: {{ $item.key }}
            operator: {{ $item.operator }}
            {{- if $item.values }}
            values:
            {{- $vals := split "," $item.values }}
            {{- range $i, $v := $vals }}
            - {{ $v | quote }}
            {{- end }}
            {{- end }}
        {{- end }}
        topologyKey: {{ $labelSelectorItem.topologyKey }}
      weight: {{ $labelSelectorItem.weight }}
    {{- end }}
    {{- range $labelSelectorIndex, $labelSelectorItem := .values.global.podAntiAffinityTermLabelSelector }}
    - podAffinityTerm:
        labelSelector:
          matchExpressions:
      {{- range $index, $item := $labelSelectorItem.labelSelector }}
          - key: {{ $item.key }}
            operator: {{ $item.operator }}
            {{- if $item.values }}
            values:
            {{- $vals := split "," $item.values }}
            {{- range $i, $v := $vals }}
            - {{ $v | quote }}
            {{- end }}
            {{- end }}
        {{- end }}
        topologyKey: {{ $labelSelectorItem.topologyKey }}
      weight: {{ $labelSelectorItem.weight }}
    {{- end }}
{{- end }}
