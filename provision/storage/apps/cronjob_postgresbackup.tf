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
              image   = "docker.io/prodrigestivill/postgres-backup-local:14@sha256:42b1104c508d1e517c8ec13df3751a49480f09a09bd857fc60fbe84cdccc4e62"
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
                path = "/backup/kubernetes/postgres-nas"
              }
            }
          }
        }
      }
    }
  }
}
