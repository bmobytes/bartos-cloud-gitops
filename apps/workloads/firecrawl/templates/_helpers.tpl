{{/*
Common labels
*/}}
{{- define "firecrawl.labels" -}}
app.kubernetes.io/part-of: firecrawl
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels for a named component
*/}}
{{- define "firecrawl.selectorLabels" -}}
app.kubernetes.io/name: firecrawl-{{ .component }}
app.kubernetes.io/part-of: firecrawl
{{- end }}

{{/*
Resolve the app secret name — either existingSecret or generated
*/}}
{{- define "firecrawl.secretName" -}}
{{- if .Values.existingSecret.name -}}
{{ .Values.existingSecret.name }}
{{- else -}}
firecrawl-secrets
{{- end -}}
{{- end }}

{{/*
Resolve the postgres secret name
*/}}
{{- define "firecrawl.pgSecretName" -}}
{{- if .Values.nuqPostgres.existingSecret.name -}}
{{ .Values.nuqPostgres.existingSecret.name }}
{{- else -}}
firecrawl-db
{{- end -}}
{{- end }}
