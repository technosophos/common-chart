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

In this document, we use `RELEASE-NAME` as the name of the release.

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

### `common.metadata`

The `common.metadata` helper generates the `metadata:` section of a Kubernetes
resource.

This takes three objects:
  - .top: top context
  - .nameOverride: override the fullname with this name
  - .metadata
    - .labels: key/value list of labels
    - .annotations: key/value list of annotations
    - .hook: name(s) of hook(s)

It generates standard labels, annotations, hooks, and a name field.

Example template:

```yaml
{{ template "common.metadata" (dict "top" . "metadata" .Values.bio) }}
---
{{ template "common.metadata" (dict "top" . "metadata" .Values.pet "nameOverride" .Values.pet.nameOverride) }}
```

Example values:

```yaml
bio:
  name: example
  labels:
    first: matt
    last: butcher
    nick: technosophos
  annotations:
    format: bio
    destination: archive
  hook: pre-install

pet:
  nameOverride: Zeus

```

Example output:

```yaml
metadata:
  name: release-name-metadata
  labels:
    app: release-name-metadata
    heritage: "Tiller"
    release: "RELEASE-NAME"
    chart: metadata-0.1.0
    first: "matt"
    last: "butcher"
    nick: "technosophos"
  annotations:
    "destination": "archive"
    "format": "bio"
    "helm.sh/hook": "pre-install"
---
metadata:
  name: Zeus
  labels:
    app: release-name-metadata
    heritage: "Tiller"
    release: "RELEASE-NAME"
    chart: metadata-0.1.0
  annotations:
```

Most of the common templates that define a resource type (e.g. `common.configmap`
or `common.job`) use this to generate the metadata, which means they inherit
the same `labels`, `annotations`, `nameOverride`, and `hook` fields.

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
    provides: release-name-service-mail # this is automatically generated
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

## `common.pod.simple`

The `common.pod.simple` template defines a basic pod. Underneath the hood,
it uses `common.podspec.simple`.

The simple pod template takes two objects:

  - `top`: The global context (usually `.`)
  - `pod`: A pod definition.

It is designed to be easily used from a values file.

Example template:

```yaml
{{- $params := dict "top" . "pod" .Values.minimalPod -}}
{{ template "common.pod.simple" $params }}
---
{{ $params := dict "top" . "pod" .Values.regularPod -}}
{{ template "common.pod.simple" $params }}
```

The above declares two pods, passing both pods data directly from the values
file. Here are the values for two pods. Note that the `minimalPod` has only
one property: `image`. All others are optional.

Example values:

```yaml
minimalPod:       # The only required field is image.
  image: nginx    # This will be resolved to nginx:latest

regularPod:
  image: alpine         # image is combined with tag.
  tag: "3.5"
  command: "sleep"
  args: ["900"]
  labels:               # This is an abritrary list of labels, appended to regular labels.
    task: "sleeper"
  annotations:
    foo: bar
  hook: "pre-install"   # Formatted as a helm hook and merged into the annotations
  volumeMounts:         # Define volume mounts and volumes.
    - mountPath: "/cache"
      name: "cache-volume"
  volumes:
    - name: "cache-volume"
      emptyDir: {}
  imagePullSecrets:     # Add imagePullSecrets if image needs them.
    - name: "dockerhub-secret"
  ports:
    - name: web
      containerPort: 8080
  env:
    - name: "ENV_VAR"
      value: "1"
    - name: "ENV_VAR2"
      value: "2"
    - name: "PASSWORD"
      valueFrom:
        secretKeyRef:
          name: "some-secret-out-there"
          key: "password"
  persistence:      # See notes on persistence.
    enabled: true
    mounts:         # If a persistence section is specified, there must be at least one mount
      - suffix: "-cache"
        path: "/cache"
      - suffix: "-data"
        path: "/var/run/data"
  livenessProbe:    # probes are passed in as-is
    httpGet:
      path: /
      port: http
    initialDelaySeconds: 120
    timeoutSeconds: 5
  readinessProbe:
    httpGet:
      path: /
      port: http
    initialDelaySeconds: 5
    timeoutSeconds: 1
  resources:        # resources are passed in as-is
    requests:
      memory: 512Mi
```

The `minimalPod` section defines a pod with the minimum number of fields, while
the `regularPod` defines many of the common attributes.

The `persistence` section has the following behavior:

- if `enabled` is true, this will use PVCs. If `false`, it will use `emptyDir`.
- both the `volumeMount` and `volume` sections are generated from the `mounts`
  data.
- volume names are generated dynamically, using `common.fullname` plus `suffix`.
- the PVC claimName is named with the same formula.
- if `persistence` is present, _at least one mount must be provided_.


The result of running the above values through the template is this:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: release-name-pod
  labels:
    app: release-name-pod
    heritage: "Tiller"
    release: "RELEASE-NAME"
    chart: pod-0.1.0
  annotations:
spec:
  containers:
    -
      image: "nginx:latest"
      imagePullPolicy: ""
---

apiVersion: v1
kind: Pod
metadata:
  name: release-name-pod
  labels:
    app: release-name-pod
    heritage: "Tiller"
    release: "RELEASE-NAME"
    chart: pod-0.1.0
    task: "sleeper"
  annotations:
    "foo": "bar"
    "helm.sh/hook": "pre-install"
spec:
  containers:
    -
      image: "alpine:3.5"
      imagePullPolicy: ""
      resources:
        requests:
          memory: 512Mi

      command: ["sleep"]
      args:
        - "900"
      env:
        - name: ENV_VAR
          value: "1"
        - name: ENV_VAR2
          value: "2"
        - name: PASSWORD
          valueFrom:
            secretKeyRef:
              key: password
              name: some-secret-out-there

      ports:
        - containerPort: 8080
          name: web

      volumeMounts:
        - name: release-name-pod-cache
          path: /cache
        - name: release-name-pod-data
          path: /var/run/data
      livenessProbe:
        httpGet:
          path: /
          port: http
        initialDelaySeconds: 120
        timeoutSeconds: 5

      readinessProbe:
        httpGet:
          path: /
          port: http
        initialDelaySeconds: 5
        timeoutSeconds: 1

  imagePullSecrets:
    - name: dockerhub-secret

  volumes:
    - name: release-name-pod-cache
      persistentVolumeClaim:
        claimName: release-name-pod-cache
    - name: release-name-pod-data
      persistentVolumeClaim:
        claimName: release-name-pod-data
```

### `common.podspec.simple` and `common.container.simple`

Two helper templates, `common.podspec.simple` and `common.container.simple`, are
used by all of the kinds that require pod specs.

### `common.job`

The `common.job.simple` template creates a new Job resource. It is highly optimized
for single-run jobs. Jobs are given names that will not collide, so any
Helm update/install operation will create a new instance of this job, even if it had done so
allready.

Jobs can also be easily created as hooks.

Jobs created with `common.job.simple` are not easy for Helm to delete, and
a `helm delete` operation _may not delete jobs created this way_ because the
job name is recreated on each run.

Example template:

```yaml
{{- $params := dict "top" . "job" .Values.someJob -}}
{{ template "common.job.simple" $params }}
```

Example values:

```yaml
someJob:
  image: alpine
  tag: "3.5"
  command: "sleep"
  args: ["900"]
  labels:               # This is an abritrary list of labels, appended to regular labels.
    task: "sleeper"
  hook: "pre-upgrade"   # Formatted as a helm hook and merged into the annotations
  restartPolicy: "Never"
```

(Note that most of the values supported for `common.podspec.simple` are also
supported for jobs)

Example output:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: release-name-job-bagwwdi    # Notice the appended random suffix
  labels:
    app: release-name-job
    heritage: "Tiller"
    release: "RELEASE-NAME"
    chart: job-0.1.0
    task: "sleeper"
  annotations:
    "helm.sh/hook": "pre-upgrade"
  spec:
    template:
      metadata:
        name: release-name-job-bagwwdi
        labels:
          app: release-name-job
          heritage: "Tiller"
          release: "RELEASE-NAME"
          chart: job-0.1.0
      spec:
        containers:
          -
            image: "alpine:3.5"
            imagePullPolicy: ""
            command: ["sleep"]
            args:
              - "900"
        restartPolicy: "Never"
```

### `common.secret`

The `common.secret` template generates Secret resources.

Configuration is very similar to `common.configmap`.

This accepts the following parameters:

- top: the top context
- secret: the secret
  - labels
  - annotations
  - hook
  - items: key/value items whose values will be base64 encoded
  - files: key/filename items whose file data will be fetched from the `.Files`
    object and placed into the map with the given key.

Note that the base64-encoded objects are formatted at 80 columns (not counting
the indent level)

Example template:
```yaml
{{ template "common.secret" (dict "top" . "secret" .Values.bio) }}
---
{{ template "common.secret" (dict "top" . "secret" .Values.pet) }}
```
The above defines two secrets.

Example values:
```yaml
bio:
  name: example
  items:
    first: matt
    last: butcher
    nick: technosophos
    bio: |-
      Matt is a software architect. He is the author of eight book, most recently
      "Go in Practice", which he co-authored with Matt Farina. Matt holds a Ph.D.
      in Philosophy from Loyola University Chicago, where he teaches in the
      Department of Computer Science.
  labels:
    format: bio
    destination: archive
  hook: pre-install

pet:
  items:
    zeus: cat
    athena: cat
    julius: cat
  files:
    one: file1.txt
```

Example output:
```yaml
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: release-name-secret
  labels:
    app: release-name-secret
    heritage: "Tiller"
    release: "RELEASE-NAME"
    chart: secret-0.1.0
    destination: "archive"
    format: "bio"
  annotations:
    "helm.sh/hook": "pre-install"
data:
  "bio": |-
    TWF0dCBpcyBhIHNvZnR3YXJlIGFyY2hpdGVjdC4gSGUgaXMgdGhlIGF1dGhvciBvZiBlaWdodCBib29
    LCBtb3N0IHJlY2VudGx5CiJHbyBpbiBQcmFjdGljZSIsIHdoaWNoIGhlIGNvLWF1dGhvcmVkIHdpdGg
    TWF0dCBGYXJpbmEuIE1hdHQgaG9sZHMgYSBQaC5ELgppbiBQaGlsb3NvcGh5IGZyb20gTG95b2xhIFV
    aXZlcnNpdHkgQ2hpY2Fnbywgd2hlcmUgaGUgdGVhY2hlcyBpbiB0aGUKRGVwYXJ0bWVudCBvZiBDb21
    dXRlciBTY2llbmNlLg==
  "first": |-
    bWF0dA==
  "last": |-
    YnV0Y2hlcg==
  "nick": |-
    dGVjaG5vc29waG9z
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: release-name-secret
  labels:
    app: release-name-secret
    heritage: "Tiller"
    release: "RELEASE-NAME"
    chart: secret-0.1.0
  annotations:
data:
  "athena": |-
    Y2F0
  "julius": |-
    Y2F0
  "zeus": |-
    Y2F0
  "one": |-
    VGhpcyBpcyBhIGZpbGUuCg==
```

### `common.configmap`

The `common.configmap` template produces ConfigMap resources.

This accepts the following parameters:

- top: the top context
- configmap: config map data
  - labels
  - annotations
  - hook
  - items: key/value items 
  - files: key/filename items whose file data will be fetched from the `.Files`
    object and placed into the map with the given key.

Example template:
```yaml
{{ template "common.configmap" (dict "top" . "configmap" .Values.bio) }}
---
{{ template "common.configmap" (dict "top" . "configmap" .Values.pet) }}
```

The above will generate two ConfigMaps that accept data from the following values.

Example values:
```yaml
bio:
  name: example
  items:
    first: matt
    last: butcher
    nick: technosophos
    bio: |-
      Matt is a software architect. He is the author of eight book, most recently
      "Go in Practice", which he co-authored with Matt Farina. Matt holds a Ph.D.
      in Philosophy from Loyola University Chicago, where he teaches in the
      Department of Computer Science.
  labels:
    format: bio
    destination: archive
  hook: pre-install

pet:
  items:
    zeus: cat
    athena: cat
    julius: cat
  files:
    one: file1.txt
```

Example output:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: release-name-configmap
  labels:
    app: release-name-configmap
    heritage: "Tiller"
    release: "RELEASE-NAME"
    chart: configmap-0.1.0
    destination: "archive"
    format: "bio"
  annotations:
    "helm.sh/hook": "pre-install"
data:
  "bio": |-
    Matt is a software architect. He is the author of eight book, most recently
    "Go in Practice", which he co-authored with Matt Farina. Matt holds a Ph.D.
    in Philosophy from Loyola University Chicago, where he teaches in the
    Department of Computer Science.
  "first": |-
    matt
  "last": |-
    butcher
  "nick": |-
    technosophos
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: release-name-configmap
  labels:
    app: release-name-configmap
    heritage: "Tiller"
    release: "RELEASE-NAME"
    chart: configmap-0.1.0
  annotations:
data:
  "athena": |-
    cat
  "julius": |-
    cat
  "zeus": |-
    cat
  "one": |-
    This is a file.
```
