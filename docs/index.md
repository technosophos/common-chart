# Common: The Helm Helper Chart

This chart is designed to make it easier for you to build and maintain Helm
charts.

It provides utilities that reflect best practices of Kubernetes chart development,
making it faster for you to write charts.

## Tips

A few tips for working with Common:

- Use `{{ include "some.template" | indent $number }}` to produce formatted output.
- Be careful when using functions that generate random data (like `common.fullname.unique`).
  They may trigger unwanted upgrades or have other side effects.

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

### `common.labels.standard`

`common.labels.standard` prints the standard set of labels.

Example usage:

```
{{ template "common.labels.standard" . }}
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

## Resource Kinds

Kubernetes defines a variety of resource kinds, from `Secret` to `StatefulSet`.
We define some of the most common kinds in a way that lets you easily work with
them.

The resource kind templates are designed to make it much faster for you to
define _basic_ versions of these resources. They don't allow you to modify
every single aspect of the definition, but they provide access to the general
information.

Often times, using these templates will require you to set up a special context
for the template with something like this:

```yaml
{{ $params := dict "top" . "service" $extraStuff }}
```

`"top"` should always point to the root context (`.`) or a facsimile.

In general, the library is designed with the idea that most information is passed
directly from the values.

### `common.service`

The `common.service` template receives the top level context and a service
definition, and creates a service resource.

Example template:

```yaml
{{ $params := dict "top" . "service" .Values.mailService -}}
{{ template "common.service" $params }}
---
{{ $params := dict "top" . "service" .Values.webService -}}
{{ template "common.service" $params }}
```

The above template defines _two_ services: a web service and a mail service. Note
that the `common.service` template defines two parameters:

  - `top`: The global context (usually `.`)
  - `service`: A service definition. In the example above, it is passed directly
    from the values.

Example values:

```yaml
# Define a mail service
mailService:
  suffix: "-mail"    # Appended to the fullname of the service (optional)
  labels:            # Appended to the labels section. (optional)
    protocol: mail
  ports:             # Composes the 'ports' section of the service definition.
    - name: smtp
      port: 22
      targetPort: 22
    - name: imaps
      port: 993
      targetPort: 993
  selector:          # This REPLACES the default selector. (optional)
    protocol: mail

# Define a web service
webService:
  suffix: "-www"
  labels:
    protocol: www
  ports:
    - name: www
      port: 80
      targetPort: 8080
  extraSelector:     # This IS APPENDED TO the default selector (optional)
    protocol: www
```

The most important part of a service definition is the `ports` object, which
defines the ports that this service will listen on. Most of the time,
`selector` is computed for you. But you can replace it or add to it.

The output of running the above values through the earlier template is:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: release-name-service-mail       # note '-mail' is the suffix.
  labels:
    provides: release-name-service-mail
    app: release-name-service           # app is not given the suffix.
    heritage: "Tiller"
    release: "RELEASE-NAME"
    chart: service-0.1.0
    protocol: "mail"
spec:
  ports:
  - port: 22
    targetPort: 22
    name: smtp
  - port: 993
    targetPort: 993
    name: imaps
  selector:
    protocol: mail

---
apiVersion: v1
kind: Service
metadata:
  name: release-name-service-www
  labels:
    provides: release-name-service-www
    app: release-name-service
    heritage: "Tiller"
    release: "RELEASE-NAME"
    chart: service-0.1.0
    protocol: "www"
spec:
  ports:
  - port: 80
    targetPort: 8080
    name: www
  selector:
    provides: release-name-service-www  # 'provides' is the default selector.
    protocol: www

```
