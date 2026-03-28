{{/* vim: set filetype=mustache: */}}

{{/*
Create a default fully qualified mongodb name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "gorse.mongodb.fullname" -}}
{{- include "cloudpirates.names.dependency.fullname" (dict "chartName" "mongodb" "chartValues" .Values.mongodb "context" $) -}}
{{- end -}}

{{- define "gorse.master.fullname" -}}
{{ printf "%s-master" (include "cloudpirates.fullname" .) }}
{{- end -}}

{{- define "gorse.server.fullname" -}}
{{ printf "%s-server" (include "cloudpirates.fullname" .) }}
{{- end -}}

{{- define "gorse.worker.fullname" -}}
{{ printf "%s-worker" (include "cloudpirates.fullname" .) }}
{{- end -}}

{{/*
Returns the available value for certain key in an existing secret (if it exists),
otherwise it generates a random value.
*/}}
{{- define "getValueFromSecret" }}
    {{- $len := (default 16 .Length) | int -}}
    {{- $obj := (lookup "v1" "Secret" .Namespace .Name).data -}}
    {{- if and $obj (hasKey $obj .Key) -}}
        {{- index $obj .Key | b64dec -}}
    {{- else -}}
        {{- randAlphaNum $len -}}
    {{- end -}}
{{- end }}

{{- define "gorse.toTOMLArray" -}}
    {{- $list := list }}
    {{- range .List }}
    {{- $list = append $list (printf "\"%s\"" .) }}
    {{- end }}
    {{- printf "[%s]" (join ", " $list) }}
{{- end }}

{{/*
Return Gorse username
*/}}
{{- define "gorse.dashboardUsername" -}}
{{- if not (empty .Values.gorse.dashboard.username) }}
    {{- .Values.gorse.dashboard.username -}}
{{- else -}}
    {{- "gorse" -}}
{{- end -}}
{{- end -}}

{{/*
Return Gorse password
*/}}
{{- define "gorse.dashboardPassword" -}}
{{- if not (empty .Values.gorse.dashboard.password) }}
    {{- .Values.gorse.dashboard.password -}}
{{- else -}}
    {{- include "getValueFromSecret" (dict "Namespace" .Release.Namespace "Name" (include "cloudpirates.fullname" .) "Length" 10 "Key" "dashboard-password") -}}
{{- end -}}
{{- end -}}

{{/*
Return Gorse API Secret
*/}}
{{- define "gorse.apiKey" -}}
{{- if not (empty .Values.gorse.api.key) }}
    {{- .Values.gorse.api.key -}}
{{- else -}}
    {{- include "getValueFromSecret" (dict "Namespace" .Release.Namespace "Name" (include "cloudpirates.fullname" .) "Length" 32 "Key" "api-key") -}}
{{- end -}}
{{- end -}}

{{/*
Return OpenAI Auth Token
*/}}
{{- define "gorse.openaiAuthToken" -}}
{{- if not (empty .Values.gorse.openai.authToken) -}}
    {{- .Values.gorse.openai.authToken -}}
{{- else -}}
    {{- $secretValue := include "getValueFromSecret" (dict "Namespace" .Release.Namespace "Name" (include "cloudpirates.fullname" .) "Length" 32 "Key" "openai-auth-token") -}}
    {{- $secretValue | default "" -}}
{{- end -}}
{{- end -}}

{{/*
Return the MongoDB Hostname
*/}}
{{- define "gorse.databaseHost" -}}
{{- if .Values.mongodb.enabled }}
    {{- if eq .Values.mongodb.architecture "replication" }}
        {{- printf "%s-primary" (include "gorse.mongodb.fullname" .) | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
        {{- printf "%s" (include "gorse.mongodb.fullname" .) -}}
    {{- end -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.host -}}
{{- end -}}
{{- end -}}

{{/*
Return the MongoDB Port
*/}}
{{- define "gorse.databasePort" -}}
{{- if .Values.mongodb.enabled }}
    {{- printf "27017" -}}
{{- else -}}
    {{- printf "%d" (.Values.externalDatabase.port | int ) -}}
{{- end -}}
{{- end -}}

{{/*
Return the MongoDB Database Name
*/}}
{{- define "gorse.databaseName" -}}
{{- if .Values.mongodb.enabled }}
    {{- printf "%s" .Values.mongodb.auth.database -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.database -}}
{{- end -}}
{{- end -}}

{{/*
Return the MongoDB User
*/}}
{{- define "gorse.databaseUser" -}}
{{- if .Values.mongodb.enabled }}
    {{- .Values.mongodb.auth.username -}}
{{- else -}}
    {{- .Values.externalDatabase.username -}}
{{- end -}}
{{- end -}}

{{/*
Return the MongoDB Secret Name
*/}}
{{- define "gorse.databaseSecretName" -}}
{{- if .Values.mongodb.enabled }}
    {{- if .Values.mongodb.auth.existingSecret -}}
        {{- printf "%s" .Values.mongodb.auth.existingSecret -}}
    {{- else -}}
        {{- printf "%s" (include "gorse.mongodb.fullname" .) -}}
    {{- end -}}
{{- else if .Values.externalDatabase.existingSecret -}}
    {{- include "cloudpirates.tplvalues.render" (dict "value" .Values.externalDatabase.existingSecret "context" $) -}}
{{- else -}}
    {{- printf "%s-externaldb" (include "cloudpirates.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the MongoDB secret key
*/}}
{{- define "gorse.databaseSecretPasswordKey" -}}
{{- if .Values.mongodb.enabled }}
    {{- printf "mongodb-passwords" -}}
{{- else -}}
    {{- .Values.externalDatabase.existingSecretPasswordKey -}}
{{- end -}}
{{- end -}}

{{/*
Return pod affinity/anti-affinity config using the chart's preset-style values.
*/}}
{{- define "gorse.affinities.pods" -}}
{{- if eq .type "soft" -}}
{{- include "cloudpirates.affinities.pods.soft" (list .component .context) -}}
{{- else if eq .type "hard" -}}
{{- include "cloudpirates.affinities.pods.hard" (list .component .context) -}}
{{- end -}}
{{- end -}}

{{/*
Return node affinity config using the chart's preset-style values.
*/}}
{{- define "gorse.affinities.nodes" -}}
{{- if and .key .values -}}
  {{- if eq .type "soft" -}}
{{- include "cloudpirates.affinities.nodes.soft" (list .key .values) -}}
  {{- else if eq .type "hard" -}}
{{- include "cloudpirates.affinities.nodes.hard" (list .key .values) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Compatibility aliases for helper names removed from newer common chart releases.
*/}}
{{- define "cloudpirates.capabilities.kubeVersion" -}}
{{- default .Capabilities.KubeVersion.Version .Values.kubeVersion -}}
{{- end -}}

{{- define "cloudpirates.names.fullname" -}}
{{- include "cloudpirates.fullname" . -}}
{{- end -}}

{{- define "cloudpirates.labels.standard" -}}
{{- include "cloudpirates.labels" . -}}
{{- end -}}

{{- define "cloudpirates.labels.matchLabels" -}}
{{- include "cloudpirates.selectorLabels" . -}}
{{- end -}}

{{- define "cloudpirates.names.dependency.fullname" -}}
{{- $chartName := .chartName -}}
{{- $chartValues := .chartValues | default dict -}}
{{- $context := .context -}}
{{- if $chartValues.fullnameOverride -}}
{{- $chartValues.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default $chartName $chartValues.nameOverride -}}
{{- if contains $name $context.Release.Name -}}
{{- $context.Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" $context.Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "cloudpirates.names.namespace" -}}
{{- include "cloudpirates.namespace" . -}}
{{- end -}}

{{- define "cloudpirates.storage.class" -}}
{{- $storageClass := .persistence.storageClass -}}
{{- if and (not $storageClass) .global.storageClass -}}
  {{- $storageClass = .global.storageClass -}}
{{- end -}}
{{- if eq $storageClass "-" -}}
storageClassName: ""
{{- else if $storageClass -}}
storageClassName: {{ $storageClass | quote }}
{{- end -}}
{{- end -}}

{{- define "cloudpirates.capabilities.ingress.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress" -}}
networking.k8s.io/v1
{{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1/Ingress" -}}
networking.k8s.io/v1beta1
{{- else -}}
extensions/v1beta1
{{- end -}}
{{- end -}}

{{- define "cloudpirates.ingress.backend" -}}
{{- $apiVersion := include "cloudpirates.capabilities.ingress.apiVersion" .context -}}
{{- if eq $apiVersion "networking.k8s.io/v1" -}}
service:
  name: {{ .serviceName }}
  port:
    {{- if kindIs "string" .servicePort }}
    name: {{ .servicePort }}
    {{- else }}
    number: {{ .servicePort }}
    {{- end }}
{{- else -}}
serviceName: {{ .serviceName }}
servicePort: {{ .servicePort }}
{{- end -}}
{{- end -}}

{{- define "cloudpirates.capabilities.deployment.apiVersion" -}}
apps/v1
{{- end -}}

{{- define "cloudpirates.capabilities.hpa.apiVersion" -}}
{{- if .context.Capabilities.APIVersions.Has "autoscaling/v2/HorizontalPodAutoscaler" -}}
autoscaling/v2
{{- else if .context.Capabilities.APIVersions.Has "autoscaling/v2beta2/HorizontalPodAutoscaler" -}}
autoscaling/v2beta2
{{- else -}}
autoscaling/v1
{{- end -}}
{{- end -}}

{{- define "cloudpirates.warnings.rollingTag" -}}
{{- if and .tag (or (eq (toString .tag) "latest") (eq (toString .tag) "master")) }}
WARNING: Rolling tags are not recommended in production.
{{- end -}}
{{- end -}}
