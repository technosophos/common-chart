# Common: The Helm Helper Chart

One little-know feature of [Helm](http://helm.sh) charts is the ability to share chart definitions
among all templates in a chart, including any of the subchart templates.

The `common` chart is a chart that defines commonly used Chart primitives that
can be used in all of your charts.

See the [Documentation](docs/index.md) for complete API documentation and examples.

## Repository

The Common chart is served out of a GitHub Pages Repository. To register the
repository, do this:

```
$ helm repo add common https://technosophos.github.io/common-chart/
```

## Example Usage

Create a new chart:

```
$ helm create mychart
```

Include the common chart as a subchart:

```console
$ cd mychart/charts
$ helm fetch common
```

Use the `common.*` definitions in your code. For example, we could add this to
a chart's `templates/service.yaml`.


```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.fullname" . }} # <--- THE IMPORTANT PART
  labels:
{{ include "common.labels.standard" . | indent 4 }} # <--- Ooo... look.
spec:
  type: {{ .Values.service.type }}
  ports:
  # common.port handles formatting of port numbers.
  - port: {{ include "common.port" .Values.service.externalPort }}
    targetPort: {{ include "common.port" .Values.service.internalPort }}
    protocol: TCP
    name: {{ .Values.service.name }}
  selector:
    app: {{ template "common.fullname" . }} # Another way to accomplish this
```

Above, we use three of the common tools:

- `common.fullname` to generate a full name for our service
- `common.labels.standard` to generate the standard labels for us
- `common.port` to format port numbers for us

The above will produce something like this:

```yaml
metadata:
  name: release-name-mychart
  labels:
    app: "release-name-mychart"
    chart: "mychart-0.1.0"
    heritage: "Tiller"
    release: RELEASE-NAME
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: nginx
  selector:
    app: release-name-mychart
```

The Common chart has many other utilities.

## Developers

If you are developing on this project, you can use `make build` to build the
charts. Note that the makefile requires signing your chart.
