# Common: A Utility Chart for Helm

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
the automatically generated `templates/service.yaml`.


```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.fullname" . }} # <--- THE IMPORTANT PART
  labels:
    chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
spec:
  type: {{ .Values.service.type }}
  ports:
  - port: {{ .Values.service.externalPort }}
    targetPort: {{ .Values.service.internalPort }}
    protocol: TCP
    name: {{ .Values.service.name }}
  selector:
    app: {{ template "common.fullname" . }} # Another way to accomplish this
```

That will use the common chart's `common.fullname` template, but use the variables
from the template in which the `common.fullname` definition is used. So the output
will be something like this:

```yaml
metadata:
  name: RELEASE-NAME-mychart
  labels:
    chart: "mychart-0.1.0"
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: nginx
  selector:
    app: RELEASE-NAME-mychart
```

## Developers

If you are developing on this project, you can use `make build` to build the
charts. Note that the makefile requires signing your chart.
