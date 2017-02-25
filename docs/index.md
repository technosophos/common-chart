# Common: The Helm Helper Chart

This chart is designed to make it easier for you to build and maintain Helm
charts.

It provides utilities that reflect best practices of Kubernetes chart development,
making it faster for you to write charts.

## Utilities

### `common.fullname`

The `common.fullname` template generates a name suitable for the `name:` field
in Kubernetes metadata. It is used like this:

```yaml
name: {{ template "common.fullname" . }}
```

The following different values can influence it:

```yaml
# By default, fullname uses '{{ .Release.Name }}-{{.Chart.Name}}. This
# overrides that and uses the given string instead.
fullnameOverride: "some-name"

# This adds a prefix
fullnamePrefix: "pre-"
# This appends a suffix
fullnameSuffix: "-suf"

# Global versions of the above
global:
  fullnamePrefix: "pp-"
  fullnameSuffix: "-ps"
```

Example output:

```yaml
---
# with the values above
name: pp-pre-some-name-suf-ps

---
# the default, for release "happy-panda" and chart "wordpress"
name: happy-panda-wordpress
```

Output of this function is truncated at 54 characters, which leaves 9 additional
characters for customized overriding. Thus you can easily extend this name
in your own charts:

```yaml
{{- define "my.fullname" -}}
  {{ template "common.fullname" . }}-my-stuff
{{- end -}}
```

### `common.fullname.unique`

The `common.fullname.unique` variant of fullname appends a unique seven-character
sequence to the end of the common name field.

This takes all of the same parameters as `common.fullname`

Example template:

```yaml
uniqueName: {{ template "common.fullname.unique" . }}
```

Example output:

```yaml
uniqueName: release-name-fullname-jl0dbwx
```

It is also impacted by the prefix and suffix definitions, as well as by
`.Values.fullnameOverride`

Note that the effective maximum length of this function is 63 characters, not 54.

### `common.labelize`

`common.labelize` turns a map into a set of labels.

Example template:

```yaml
{{- $map := dict "first" "1" "second" "2" "third" "3" -}}
{{- template "common.labelize" $map -}}
```

Example output:

```yaml
first: "1"
second: "2"
third: "3"
```

### `common.standard.labels`

`common.standard.labels` prints the standard set of labels.

Example usage:

```
{{ template "common.standard.labels" . }}
```

Example output:

```yaml
app: release-name-labelizer
heritage: "Tiller"
release: "RELEASE-NAME"
chart: labelizer-0.1.0
```

### `common.hook`

The `common.hook` template is a convenience for defining hooks.

Example template:

```yaml
{{ template "common.hook" "pre-install,post-install" }}
```

Example output:

```yaml
"helm.sh/hook": "pre-install,post-install"
```

### `common.chartref`

The `common.chartref` helper prints the chart name and version, escaped to be
legal in a Kubernetes label field.

Example template:

```yaml
chartref: {{ template "common.chartref" . }}
```

For the chart `foo` with version `1.2.3-beta.55+1234`, this will render:

```yaml
chartref: foo-1.2.3-beta.55_1234
```

(Note that `+` is an illegal character in label values)

### `common.port` and `common.port.string`

`common.port` takes a port in either numeric or colon-numeric (":8080") syntax
and converts it to an integer.

`common.port.string` does the same, but formats the result as a string (in quotes)
to satisfy a few places in Kubernetes where ports are passed as strings.

Example template:

```yaml
port1: {{ template "common.port" 1234 }}
port2: {{ template "common.port" "4321" }}
port3: {{ template "common.port" ":8080" }}
portString: {{ template "common.port.string" 1234 }}
```

Example output:
```yaml
port1: 1234
port2: 4321
port3: 8080
portString: "1234"
```
