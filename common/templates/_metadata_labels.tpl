{{- /*
common.labelize takes a dict or map and generates labels.

Values will be quoted. Keys will not.

Example output:

  first: "Matt"
  last: "Butcher"

*/ -}}
{{- define "common.labelize" -}}
{{- range $k, $v := . }}
{{ $k }}: {{ $v | quote }}
{{- end -}}
{{- end -}}

{{- /*
common.labels.standard prints the standard Helm labels.

The standard labels are frequently used in metadata.
*/ -}}
{{- define "common.labels.standard" -}}
app: {{template "common.fullname" .}}
heritage: {{ .Release.Service | quote }}
release: {{ .Release.Name | quote }}
chart: {{template "common.chartref" . }}
{{- end -}}
