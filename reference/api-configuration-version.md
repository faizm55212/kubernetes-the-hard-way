# Kubernetes API Versions Reference (v1.32.3)

| Resource Type                      | API Group                             | Kind(s) Example                        | Recommended `apiVersion` |
|------------------------------------|----------------------------------------|----------------------------------------|---------------------------|
| **Core objects**                   | (core / legacy)                        | Pod, Service, ConfigMap, Secret, Node  | `v1`                      |
| **RBAC**                           | rbac.authorization.k8s.io              | Role, ClusterRole, RoleBinding         | `v1`                      |
| **Kubelet Configuration**          | kubelet.config.k8s.io                  | KubeletConfiguration                   | `v1beta1`                 |
| **API Server Configuration**       | apiserver.config.k8s.io                | APIServerConfiguration                 | `v1` or `v1beta1`         |
| **Scheduler Configuration**        | kubescheduler.config.k8s.io            | KubeSchedulerConfiguration             | `v1`                      |
| **Controller Manager Configuration** | kubecontroller.config.k8s.io         | KubeControllerManagerConfiguration     | `v1`                      |
| **NetworkPolicy**                  | networking.k8s.io                      | NetworkPolicy                          | `v1`                      |
| **Ingress**                        | networking.k8s.io                      | Ingress                                | `v1`                      |
| **Deployments, ReplicaSets, etc.** | apps                                   | Deployment, DaemonSet, StatefulSet     | `v1`                      |
| **CustomResourceDefinitions (CRD)**| apiextensions.k8s.io                   | CustomResourceDefinition               | `v1`                      |
| **APIService (Aggregation Layer)** | apiregistration.k8s.io                 | APIService                             | `v1`                      |
| **Certificate Signing Requests**   | certificates.k8s.io                    | CertificateSigningRequest              | `v1`                      |
| **Events**                         | events.k8s.io / core                   | Event                                  | `v1`                      |
| **AdmissionConfiguration**         | apiserver.config.k8s.io                | AdmissionConfiguration                 | `v1`                      |
| **AuditPolicy**                    | (static file, not in API server)       | AuditPolicy                            | `v1`                      |
| **Storage Classes, PVCs**          | storage.k8s.io                         | StorageClass, CSIDriver, VolumeAttachment | `v1`                  |
| **HorizontalPodAutoscaler**        | autoscaling                            | HorizontalPodAutoscaler                | `v2`                      |

