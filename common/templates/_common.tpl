{{/*
The commons templates provide basic implementations common to many Chart
templates.

*/}}


{{define "common.chartref"}}{{printf "%s-%s" .Chart.Name .Chart.Version}}{{end}}

{{/*
The common labels that are frequently used in metadata.
*/}}
{{define "common.metadata.labels"}}
    app: {{template "common.fullname" .}}
    heritage: {{ .Release.Service | quote }}
    release: {{ .Release.Name | quote }}
    chart: {{template "common.chartref" . }}
{{end}}

{{/*
Define a hook.

This is to be used in a 'metadata:annotations' section.

This should be called as 'template "common.metadata.hook" "post-install"'
*/}}
{{- define "common.metadata.hook"}}
    "helm.sh/hook": {{printf "%s" . | quote}}
{{- end}}
