provider "aws" {
  region = "eu-west-2"
}

data "aws_region" "current" {}

data "aws_eks_cluster" "eks_cluster" {
  name = "cp-0408-0936"
}

data "aws_caller_identity" "current" {}

# Create a Secrets Manager secret (manually add values via console if you want)
resource "aws_secretsmanager_secret" "test" {
  name                    = "test-es-plain-secret"
  recovery_window_in_days = 7
  description             = "A test secret to sync with External Secrets Operator"
  tags = {
    "target-k8s-secret-name" = "k8s-synced-secret"
  }
}

# Create SecretStore
resource "kubernetes_manifest" "secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "SecretStore"
    metadata = {
      name      = "test-secret-store"
      namespace = "external-secrets-operator"
      labels = {
        "managed/by" = "terraform"
      }
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = data.aws_region.current.name
        #   auth = {
        #     jwt = {
        #       serviceAccountRef = {
        #         name = "external-secrets-irsa-sa" # Replace with your IRSA service account name
        #       }
        #     }
        #   }
        }
      }
    }
  }
}

# Create ExternalSecret
resource "kubernetes_manifest" "external_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "test-external-secret"
      namespace = "external-secrets-operator"
      labels = {
        "managed/by" = "terraform"
      }
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "test-secret-store"
        kind = "SecretStore"
      }
      target = {
        name = "k8s-synced-secret"
        creationPolicy = "Owner"
      }
      dataFrom = [
        {
          extract = {
            key = aws_secretsmanager_secret.test.name
          }
        }
      ]
    }
  }
}