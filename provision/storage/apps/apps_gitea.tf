
resource "helm_release" "gitea" {
  name       = "gitea"

  repository = "https://dl.gitea.io/charts/"
  chart      = "gitea"
  version    = "8.3.0"

  values = [
    yamlencode({
      image = {
        repository = "gitea/gitea"
        tag = "1.19.3"
        pullPolicy = "IfNotPresent"
        rootless = false
      }
      containerSecurityContext = {
        capabilities = {
          add = [
            "SYS_CHROOT"
          ]
        }
      }
      service = {
        ssh = {
          type = "LoadBalancer"
          port = 222
          externalTrafficPolicy = "Local"
        }
        http = {
          type = "LoadBalancer"
          port = 8687
          externalTrafficPolicy = "Local"
        }
      }
      memcached = {
        enabled = true
      }
      persistence = {
        enabled = true
        existingClaim = "gitea-config-pvc"
      }
      postgresql = {
        enabled = false
      }
      mysql = {
        enabled = false
      }
      mariadb = {
        enabled = false
      }
      gitea = {
        admin = {
          APP_NAME = "Gitea: Git with a cup of tea"
          "cron.resync_all_sshkeys" = {
            ENABLED = true
            RUN_AT_START = true
          }
        }
        config = {
          server = {
            SSH_PORT = "22"
            SSH_LISTEN_PORT = "22"
            root_url = "https://gitea.${data.sops_file.secrets.data["secret_domain"]}"
          }
          database = {
            DB_TYPE = "postgres"
            HOST = "postgres:5432"
            NAME = "gitea"
            PASSWD = "${data.sops_file.secrets.data["gitea_database_password"]}"
            USER = "gitea"
          }
        }
      }

      # podSecurityPolicy = {
      #   enabled = true
      # }
      # server            = {
      #   persistentVolume = {
      #     enabled = false
      #   }
      #   resources        = {
      #     limits   = {
      #       cpu    = "5m"
      #       memory = "256Mi"
      #     }
      #     requests = {
      #       memory = "256Mi"
      #     }
      #   }
      # }
    })
  ]
}

resource "kubernetes_persistent_volume_claim_v1" "gitea-pvc" {
  metadata {
    name = "gitea-config-pvc"
  }
  spec {
    storage_class_name = "manual"
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    volume_name = "${kubernetes_persistent_volume_v1.gitea-pv.metadata.0.name}"
  }
}

resource "kubernetes_persistent_volume_v1" "gitea-pv" {
  metadata {
    name = "gitea-config-pv"
  }
  spec {
    storage_class_name = "manual"
    capacity = {
      storage = "1Gi"
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      host_path {
        path = "/spool/gitea"
      }
    }
  }
}
