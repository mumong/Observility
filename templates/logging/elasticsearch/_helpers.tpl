{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "elasticsearch.name" -}}
{{- default .Chart.Name .Values.logging.elasticsearch.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "elasticsearch.fullname" -}}
{{- $name := default .Chart.Name .Values.logging.elasticsearch.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Unified name: uname
*/}}
{{- define "elasticsearch.uname" -}}
{{- if empty .Values.logging.elasticsearch.fullnameOverride -}}
{{- if empty .Values.logging.elasticsearch.nameOverride -}}
{{ .Values.logging.elasticsearch.clusterName }}-{{ .Values.logging.elasticsearch.nodeGroup }}
{{- else -}}
{{ .Values.logging.elasticsearch.nameOverride }}-{{ .Values.logging.elasticsearch.nodeGroup }}
{{- end -}}
{{- else -}}
{{ .Values.logging.elasticsearch.fullnameOverride }}
{{- end -}}
{{- end -}}

{{/*
Generate certificates when the secret doesn't exist
*/}}
{{- define "elasticsearch.gen-certs" -}}
{{- $certs := lookup "v1" "Secret" .Release.Namespace ( printf "%s-certs" (include "elasticsearch.uname" . ) ) -}}
{{- if $certs -}}
tls.crt: {{ index $certs.data "tls.crt" }}
tls.key: {{ index $certs.data "tls.key" }}
ca.crt: {{ index $certs.data "ca.crt" }}
{{- else -}}
{{- $masterService := include "elasticsearch.masterService" . -}}
{{- $headlessService := printf "%s-headless" $masterService -}}
{{- $altNames := list $masterService $headlessService ( printf "%s.%s" $masterService .Release.Namespace ) ( printf "%s.%s.svc" $masterService .Release.Namespace ) ( printf "%s.%s" $headlessService .Release.Namespace ) ( printf "%s.%s.svc" $headlessService .Release.Namespace ) -}}
{{- $ca := genCA "elasticsearch-ca" 3650 -}}
{{- $cert := genSignedCert $masterService nil $altNames 3650 $ca -}}
tls.crt: {{ $cert.Cert | toString | b64enc }}
tls.key: {{ $cert.Key | toString | b64enc }}
ca.crt: {{ $ca.Cert | toString | b64enc }}
{{- end -}}
{{- end -}}

{{/*
Generate master service name
*/}}
{{- define "elasticsearch.masterService" -}}
{{- if .Values.logging.elasticsearch.masterService -}}
  {{ .Values.logging.elasticsearch.masterService }}
{{- else -}}
  {{- if .Values.logging.elasticsearch.fullnameOverride -}}
    {{ .Values.logging.elasticsearch.fullnameOverride }}
  {{- else -}}
    {{- if .Values.logging.elasticsearch.nameOverride -}}
      {{ .Values.logging.elasticsearch.nameOverride }}-master
    {{- else -}}
      {{ .Values.logging.elasticsearch.clusterName }}-master
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}


{{/*
Generate StatefulSet endpoints list
*/}}
{{- define "elasticsearch.endpoints" -}}
{{- $replicas := int (toString (.Values.logging.elasticsearch.replicas)) }}
{{- $uname := (include "elasticsearch.uname" .) }}
  {{- range $i, $_ := untilStep 0 $replicas 1 }}
{{ $uname }}-{{ $i }},
  {{- end -}}
{{- end -}}

{{/*
List of node roles
*/}}
{{- define "elasticsearch.roles" -}}
{{- range $.Values.logging.elasticsearch.roles }}
{{ . }},
{{- end -}}
{{- end -}}

{{/*
Determine ES major version from tag or fallback to 8
*/}}
{{- define "elasticsearch.esMajorVersion" -}}
{{- if .Values.logging.elasticsearch.esMajorVersion -}}
{{ .Values.logging.elasticsearch.esMajorVersion }}
{{- else -}}
{{- $tag := .Values.logging.elasticsearch.imageTag | default "8.11.1" -}}
{{- $version := int (index ($tag | splitList ".") 0) -}}
  {{- if and (contains "docker.elastic.co/elasticsearch/elasticsearch" (.Values.logging.elasticsearch.image | default "")) (not (eq $version 0)) -}}
{{ $version }}
  {{- else -}}
8
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Determine serviceAccount name
*/}}
{{- define "elasticsearch.serviceAccount" -}}
{{- .Values.logging.elasticsearch.rbac.serviceAccountName | default (include "elasticsearch.uname" .) -}}
{{- end -}}
