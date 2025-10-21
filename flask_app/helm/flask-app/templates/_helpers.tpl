{{/* ----------------------------------------------------------------------
  Name helper
  Returns the chart name or overridden name
---------------------------------------------------------------------- */}}
{{- define "flask-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* ----------------------------------------------------------------------
  Fullname helper
  Returns a unique full name for resources: name-namespace
---------------------------------------------------------------------- */}}
{{- define "flask-app.fullname" -}}
{{- printf "%s-%s" (include "flask-app.name" .) .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* ----------------------------------------------------------------------
  Labels helper
  Standard labels for all resources
---------------------------------------------------------------------- */}}
{{- define "flask-app.labels" -}}
app.kubernetes.io/name: {{ include "flask-app.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
 