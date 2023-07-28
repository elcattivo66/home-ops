resource "kubernetes_cron_job_v1" "postgres-backup" {
  metadata {
    name = "postgres-backup"
    namespace = "default"
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    schedule                      = "35 3 * * *"
    timezone                      = "Europe/Berlin"
    starting_deadline_seconds     = 10
    successful_jobs_history_limit = 10
    job_template {
      metadata {}
      spec {
        backoff_limit              = 2
        ttl_seconds_after_finished = 10
        template {
          metadata {}
          spec {
            container {
              name    = "postgres-backup"
              image   = "docker.io/prodrigestivill/postgres-backup-local:15@sha256:f4286b82a1828d3e711dc2e5c363a47ddd6a26f2dc0d214f7143a175e2e3c0bb"
              command = ["/backup.sh"]
              env {
                name = "POSTGRES_HOST"
                value = "postgres.default.svc.cluster.local"
              }
              env {
                name = "POSTGRES_PORT"
                value = "5432"
              }
              env {
                name = "POSTGRES_USER"
                value = "postgres"
              }
              env {
                name = "POSTGRES_PASSWORD"
                value = "${data.sops_file.secrets.data["postgres_password"]}"
              }
              env {
                name = "POSTGRES_DB"
                value = "gitea"
              }
              volume_mount {
                name       = "nas-backups"
                mount_path = "/backups"
              }
            }
            volume {
              name = "nas-backups"
              nfs {
                server = "nas"
                path = "/tank/backup/kubernetes/postgres-nas"
              }
            }
          }
        }
      }
    }
  }
}
