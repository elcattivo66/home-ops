resource "kubernetes_stateful_set_v1" "gitea" {
  metadata {
    name      = "gitea"
    namespace = "default"
    labels = {
      "app.arpa.home/name" = "gitea"
    }
  }
  spec {
    selector {
      match_labels = {
        "app.arpa.home/name" = "gitea"
      }
    }
    service_name = "gitea"
    replicas     = 1
    template {
      metadata {
        labels = {
          "app.arpa.home/name" = "gitea"
        }
      }
      spec {
        container {
          name              = "main"
          image             = "gitea/gitea:1.19.3"
          image_pull_policy = "IfNotPresent"

          # env {
          #   name  = "USER_ID"
          #   value = "1000"
          # }
          # env {
          #   name  = "GROUP_ID"
          #   value = "1000"
          # }
          env {
            name  = "GITEA__database__HOST"
            value = "postgres:5432"
          }
          env {
            name = "GITEA__database__USER"
            value = "${data.sops_file.secrets.data["gitea_database_user"]}"
          }
          env {
            name = "GITEA__database__PASSWD"
            value = "${data.sops_file.secrets.data["gitea_database_password"]}"
          }
          env {
            name  = "GITEA__database__DB_TYPE"
            value = "postgres"
          }
          env {
            name  = "GITEA__database__NAME"
            value = "gitea"
          }

          port {
            name           = "ssh"
            container_port = 22
            host_port      = 222
          }
          port {
            name           = "ui"
            container_port = 3000
            host_port      = 8687
          }
          # volume_mount {
          #   name       = "data"
          #   mount_path = "/var/lib/gitea"
          # }
          volume_mount {
            name       = "config"
            mount_path = "/data"
          }
          resources {
            requests = {
              cpu    = "5m"
              memory = "10Mi"
            }
            limits = {
              memory = "150Mi"
            }
          }
        }
        # security_context {
        #   run_as_user = 1000
        #   run_as_group = 1000
        #   fs_group = 1000
        #   fs_group_change_policy = "OnRootMismatch"
        # }
        toleration {
          effect   = "NoSchedule"
          operator = "Exists"
        }
        volume {
          name = "data"
          host_path {
            path = "/spool/gitea/data"
          }
        }
        volume {
          name = "config"
          host_path {
            path = "/spool/gitea"
          }
        }
      }
    }
    update_strategy {
      type = "RollingUpdate"
    }
  }
}

resource "kubernetes_service_v1" "gitea" {
  metadata {
    name      = "gitea"
    namespace = "default"
    labels = {
      "app.arpa.home/name" = "gitea"
    }
  }
  spec {
    selector = {
      "app.arpa.home/name" = "gitea"
    }
    port {
      name        = "ssh"
      port        = 222
      target_port = 222
      protocol    = "TCP"
    }
    port {
      name        = "ui"
      port        = 8687
      target_port = 8687
      protocol    = "TCP"
    }
  }
}

# resource "kubernetes_ingress_v1" "gitea" {
#   metadata {
#     name      = "gitea-ssh"
#     namespace = "default"
#     annotations = {
#       "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
#     }
#     labels = {
#       "app.arpa.home/name" = "gitea"
#     }
#   }
#   spec {
#     ingress_class_name = "traefik"
#     rule {
#       host = "gitea-ssh.nas.local"
#       http {
#         path {
#           path      = "/"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = "gitea"
#               port {
#                 number = 222
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }
