{{/*
Expand the name of the chart.
*/}}
{{- define "gordo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gordo.fullname" -}}
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
Create gordo-controller name.
*/}}
{{- define "gordo.controller.fullname" -}}
{{- printf "%s-%s" (include "gordo.fullname" .) .Values.controller.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "gordo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "gordo.labels" -}}
helm.sh/chart: {{ include "gordo.chart" .context }}
{{ include "gordo.selectorLabels" (dict "context" .context "component" .component) }}
{{- if .component }}
app.kubernetes.io/component: {{ .component }}
{{- end }}
{{- if .context.Chart.AppVersion }}
app.kubernetes.io/version: {{ .context.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .context.Release.Service }}
{{- with .context.Values.extraLabels }}
{{- range $name, $label := . }}
{{- $v := tpl $label $.context }}
{{ $name }}: {{ $v | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
spec.template.metadata labels.
*/}}
{{- define "gordo.podTemplate.labels" -}}
{{ include "gordo.selectorLabels" (dict "context" .context "component" .component) }}
{{- with .context.Values.podLabels }}
{{- range $name, $label := . }}
{{- $v := tpl $label $.context }}
{{ $name }}: {{ $v | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "gordo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gordo.name" .context }}{{ ternary "" (printf "-%s" .component) (empty .component) }}
app.kubernetes.io/instance: {{ .context.Release.Name }}
{{- end }}

{{/*
Create the name of the gordo-controller service account to use.
*/}}
{{- define "gordo.controller.serviceAccountName" -}}
{{- if .Values.controller.serviceAccount.create }}
{{- default (include "gordo.controller.fullname" .) .Values.controller.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.controller.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
controller RESOURCES_LABELS.
*/}}
{{- define "gordo.controller.resourcesLabels" -}}
{{- $labels := dict }}
{{- range $name, $label := .Values.extraLabels }}
{{- $v := tpl $label $ }}
{{- $labels := set $labels $name $v}}
{{- end }}
{{- range $name, $label := .Values.podLabels }}
{{- $v := tpl $label $ }}
{{- $labels := set $labels $name $v}}
{{- end }}
{{- toJson $labels }}
{{- end -}}

{{/*
gordo-controller default env.
*/}}
{{- define "gordo.controller.defaultEnvs" -}}
{{ $env := dict }}
{{ $env := set $env "RUST_LOG" .Values.controller.rustLog }}
{{ $env := set $env "DEFAULT_DEPLOY_ENVIRONMENT" (toJson .Values.controller.defaultDeployEnvironment) }}
{{ $env := set $env "RESOURCES_LABELS" (include "gordo.controller.resourcesLabels" . ) }}
{{ $env := set $env "ARGO_SERVICE_ACCOUNT" (include "gordo.argoRunner.serviceAccountName" . ) }}
{{ $env := set $env "DEPLOY_IMAGE" (include "gordo.image" (dict "context" . "image" .Values.controller.deployImage)) }}
{{ $env := set $env "DOCKER_REGISTRY" .Values.controller.deployImage.registry }}
{{ $env := set $env "SERVER_PORT" .Values.controller.containerPort }}
{{ toJson $env }}
{{- end -}}

{{/*
Return full image name.
*/}}
{{- define "gordo.image" -}}
{{- if and .image.registry .image.repository -}}
  {{- .image.registry }}/{{ .image.repository }}
{{- else -}}
  {{- .image.repository }}
{{- end -}}
{{- end -}}

{{/*
Ingress apiVersion.
*/}}
{{- define "gordo.ingress.apiVersion" -}}
{{- if semverCompare ">=1.19-0" .Capabilities.KubeVersion.GitVersion -}}
apiVersion: networking.k8s.io/v1
{{- else if semverCompare ">=1.14-0" .Capabilities.KubeVersion.GitVersion -}}
apiVersion: networking.k8s.io/v1beta1
{{- else -}}
apiVersion: extensions/v1beta1
{{- end }}
{{- end -}}

{{/*
argo-runner name.
*/}}
{{- define "gordo.argoRunner.fullname" -}}
{{- printf "%s-%s" (include "gordo.fullname" .) .Values.argoRunner.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
argo-runner service name.
*/}}
{{- define "gordo.argoRunner.serviceAccountName" -}}
{{- if .Values.controller.serviceAccount.create }}
{{- default (include "gordo.argoRunner.fullname" .) .Values.argoRunner.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.argoRunner.serviceAccount.name }}
{{- end }}
{{- end -}}

{{/*
Istio Gateway selector.
*/}}
{{- define "gordo.istio.gatewaySelector" -}}
{{- if .Values.istio.gateway.selector -}}
{{ toYaml .Values.istio.gateway.selector }}
{{- else -}}
istio: ingressgateway
{{- end -}}
{{- end -}}

{{/*
VirtualService hosts.

TODO make this function more general
*/}}
{{- define "gordo.controller.virtualServiceHosts" -}}
{{- if .Values.controller.istio.hosts -}}
{{- toYaml .Values.controller.istio.hosts }}
{{- else -}}
- "*"
{{- end -}}
{{- end -}}

{{/*
VirtualService gateways.

TODO make this function more general
*/}}
{{- define "gordo.controller.virtualServiceGateways" -}}
{{- if .Values.controller.istio.gateways -}}
{{- toYaml .Values.controller.istio.gateways }}
{{- else -}}
{{- if .Values.istio.gateway.create -}}
- {{ include "gordo.controller.fullname" . }}
{{- else -}}
{{- /* TODO make this field adjustable through gordo environment variable. */ -}}
- istio-system/istio-gateway
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Default Ingress local host.
*/}}
{{- define "gordo.ingress.defaultHost" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}.local
{{- end -}}

{{/*
pathPerfix for controller ingress.
*/}}
{{- define "gordo.controller.pathPrefix" -}}
{{- if not (empty .Values.controller.pathPrefix) -}}
{{ .Values.controller.pathPrefix }}
{{- else -}}
{{- if eq .Values.controller.ingress.className "nginx" -}}
{{ "/" }}{{- include "gordo.controller.fullname" . -}}/(.*)
{{- else -}}
{{ "/" }}{{- include "gordo.controller.fullname" . -}}
{{- end -}}
{{- end -}}
{{- end -}}
