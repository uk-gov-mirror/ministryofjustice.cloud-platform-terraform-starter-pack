
# Namespace

resource "kubernetes_namespace" "starter_pack" {
  count = var.enable_starter_pack ? var.starter_pack_count : 0

  metadata {
    name = "${var.namespace}-${count.index}"

    labels = {
      "name"                               = "${var.namespace}-${count.index}"
      "pod-security.kubernetes.io/enforce" = "restricted"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"   = "Cloud Platform starter pack test app"
      "cloud-platform.justice.gov.uk/business-unit" = "cloud-platform"
      "cloud-platform.justice.gov.uk/owner"         = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"   = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
}

resource "random_password" "adminpassword" {
  count = var.enable_starter_pack ? var.starter_pack_count : 0

  length  = 16
  special = false
}

resource "random_password" "password" {
  count = var.enable_starter_pack ? var.starter_pack_count : 0

  length  = 16
  special = false
}

resource "kubernetes_secret" "container_postgres_secrets" {
  count = var.enable_postgres_container && var.multi_container_app && var.enable_starter_pack ? var.starter_pack_count : 0

  metadata {
    name      = "container-postgres-secrets"
    namespace = kubernetes_namespace.starter_pack[count.index].id
  }

  data = {
    postgresql-postgres-password = random_password.adminpassword[0].result
    postgresql-password          = random_password.password[0].result
  }
  type = "Opaque"
}

resource "kubernetes_secret" "postgresurl_secret" {
  count = var.enable_postgres_container && var.multi_container_app && var.enable_starter_pack ? var.starter_pack_count : 0

  type = "Opaque"

  metadata {
    name      = "postgresurl-secret"
    namespace = kubernetes_namespace.starter_pack[count.index].id
  }

  data = {
    url = format(
      "%s%s:%s@%s.%s.%s",
      "postgres://",
      "postgres",
      kubernetes_secret.container_postgres_secrets[count.index].data.postgresql-password,
      "multi-container-app-postgresql",
      "${var.namespace}-${count.index}",
      "svc.cluster.local:5432/multi_container_demo_app",
    )
  }
}

resource "helm_release" "helloworld" {
  count = var.helloworld && var.enable_starter_pack ? var.starter_pack_count : 0

  name       = "helloworld"
  namespace  = kubernetes_namespace.starter_pack[count.index].id
  chart      = "helloworld"
  repository = "https://ministryofjustice.github.io/cloud-platform-helm-charts"
  version    = var.helloworld_version

  values = [templatefile("${path.module}/templates/helloworld.yaml.tpl", {
    helloworld-ingress = format(
      "%s-%s.%s.%s",
      "helloworld-app",
      "${var.namespace}-${count.index}",
      "apps",
      var.cluster_domain_name,
    )
  })]
}

resource "helm_release" "multi_container_app" {
  count = var.multi_container_app && var.enable_starter_pack ? var.starter_pack_count : 0

  name       = "multi-container-app"
  namespace  = kubernetes_namespace.starter_pack[count.index].id
  chart      = "multi-container-app"
  repository = "https://ministryofjustice.github.io/cloud-platform-helm-charts"
  version    = var.multi_container_app_version

  values = [templatefile("${path.module}/templates/multi-container-app.yaml.tpl", {
    multi-container-app-ingress = format(
      "%s-%s.%s.%s",
      "multi-container-app",
      "${var.namespace}-${count.index}",
      "apps",
      var.cluster_domain_name,
    )

    postgres-enabled = var.enable_postgres_container
  })]
  set_sensitive = [
    {
      name  = "databaseUrlSecretName"
      value = var.enable_postgres_container ? "postgresurl-secret" : var.rds_secret
    }
  ]

  set = [
    {
      name  = "postgresql.image.registry"
      value = "docker.io"
    },
    {
      name  = "postgresql.image.repository"
      value = "bitnamilegacy/postgresql"
    },
    {
      name  = "postgresql.image.tag"
      value = "11.2.0-debian-9-r49"
    },
    {
      name  = "postgresql.global.security.allowInsecureImages"
      value = "true"
    }
  ]
}

