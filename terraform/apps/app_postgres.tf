resource "kubernetes_stateful_set_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "default"
    labels = {
      "app.arpa.home/name" = "postgres"
    }
  }
  spec {
    selector {
      match_labels = {
        "app.arpa.home/name" = "postgres"
      }
    }
    service_name = "postgres"
    replicas     = 1
    template {
      metadata {
        labels = {
          "app.arpa.home/name" = "postgres"
        }
      }
      spec {
        container {
          name              = "main"
          image             = "bitnami/postgresql:15.5.0"
          image_pull_policy = "IfNotPresent"

          env {
            name = "POSTGRESQL_POSTGRES_PASSWORD"
            value = "${data.sops_file.secrets.data["postgres_password"]}"
          }
          env {
            name = "POSTGRESQL_USERNAME"
            value = "gitea"
          }
          env {
            name = "POSTGRESQL_PASSWORD"
            value = "${data.sops_file.secrets.data["gitea_database_password"]}"
          }
          env {
            name = "POSTGRESQL_DATABASE"
            value = "gitea"
          }
          port {
            name           = "postgres"
            container_port = 5432
            host_port      = 5432
          }
          volume_mount {
            name       = "postgres-data"
            mount_path = "/bitnami/postgresql"
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
        toleration {
          effect   = "NoSchedule"
          operator = "Exists"
        }
        volume {
          name = "postgres-data"
          host_path {
            path = "/spool/postgres"
          }
        }
      }
    }
    # volume_claim_template {
    #   metadata {
    #     name = "postgres-data"
    #   }
    #   spec {
    #     access_modes       = ["ReadWriteOnce"]
    #     storage_class_name = "local-path"

    #     resources {
    #       requests = {
    #         storage = "1Gi"
    #       }
    #     }
    #   }
    # }
    update_strategy {
      type = "RollingUpdate"
    }
  }
}

resource "kubernetes_service_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "default"
    labels = {
      "app.arpa.home/name" = "postgres"
    }
  }
  spec {
    selector = {
      "app.arpa.home/name" = "postgres"
    }
    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }
  }
}

