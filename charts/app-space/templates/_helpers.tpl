{{- define "app.infraAnnotations" }}
  checksum/infra-secrets: {{ include (print $.Template.BasePath "/infra-secrets.yaml") . | sha256sum }}
  checksum/configmap: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
{{- end -}}

{{- define "app.containerProbes" -}}
{{- .type }}:
  {{- if .probe.exec }}
  exec: {{ .probe.exec }}
  {{- end }}
  failureThreshold: {{ .probe.failureThreshold | default 3 }}
  initialDelaySeconds: {{ .probe.initialDelaySeconds | default 40 }}
  periodSeconds: {{ .probe.periodSeconds | default 5 }}
  successThreshold: {{ .probe.successThreshold | default 1 }}
  timeoutSeconds: {{ .probe.timeoutSeconds | default 20 }}
  {{- if .probe.httpGet }}
  httpGet:
    path: {{ .probe.httpGet.path }}
    port: {{ .probe.httpGet.port }}
  {{- end }}
  {{- if .probe.tcpSocket }}
  tcpSocket:
    port: {{ .probe.tcpSocket.port }}
  {{- end }}
{{- end }}

{{- define "app.nodeAffinity" }}
{{- $nodeAffinityLabels := . -}}
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
      - matchExpressions:
          {{- range $index, $label := $nodeAffinityLabels }}
          - key: {{ $label.name }}
            operator: In
            values:
              - {{ $label.value }}
          {{- end }}
{{- end -}}

{{- define "app.requiredPodAntiAffinity" }}
{{- $podAntiAffinityLabels := . -}}
requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchExpressions:
        {{- range $index, $label := $podAntiAffinityLabels }}
        - key: {{ $label.name }}
          operator: In
          values:
            - {{ $label.value }}
        {{- end }}
    topologyKey: kubernetes.io/hostname
{{- end -}}

{{- define "app.preferredPodAntiAffinity" }}
{{- $podAntiAffinityLabels := . -}}
preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchExpressions:
          {{- range $index, $label := $podAntiAffinityLabels }}
          - key: {{ $label.name }}
            operator: In
            values:
              - {{ $label.value }}
          {{- end }}
      topologyKey: kubernetes.io/hostname
{{- end -}}

{{/*
Renders affinity block in the manifests
*/}}
{{- define "app.affinity" }}
affinity:
  {{- if .nodeAffinityLabels }}
  {{- include "app.nodeAffinity" .nodeAffinityLabels | nindent 2 }}
  {{- end }}
  {{- if .podAntiAffinity }}
  podAntiAffinity:
  {{- if eq .podAntiAffinity.type "required" }}
  {{- include "app.requiredPodAntiAffinity" .podAntiAffinity.labels | nindent 4 }}
  {{- end }}
  {{- if eq .podAntiAffinity.type "preferred" }}
  {{- include "app.preferredPodAntiAffinity" .podAntiAffinity.labels | nindent 4 }}
  {{- end }}
  {{- end }}
{{- end -}}

{{- define "app.nodeLabels" }}
{{- if . }}
nodeSelector:
  {{ toYaml . }}
{{- end -}}
{{- end -}}