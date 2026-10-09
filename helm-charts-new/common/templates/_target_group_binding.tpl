{{- define "common.targetGroupBinding" }}

{{- if .Values.targetGroupBinding.enabled }}
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: {{ .Values.targetGroupBinding.name }}
  # namespace: shopverse-dev
  {{- with .Values.labels }}
  labels:
  {{- toYaml . | nindent 4 }}
  {{- end }}
{{- if .Values.targetGroupBinding.values }}
spec:
  targetType: {{ .Values.targetGroupBinding.values.targetType }}   # ip
  serviceRef:
    name: {{ .Values.service.name }}           # shopverse-frontend
    port: {{ .Values.service.port }}           # 8080
  targetGroupName: {{ .Values.targetGroupBinding.values.targetGroupName }}   # shopverse-dev-frontend-tg
  # targetGroupARN: REPLACE_WITH_FRONTEND_TARGET_GROUP_ARN
{{- end }}
{{- end }}

{{- end }}
