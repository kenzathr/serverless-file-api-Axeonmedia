# Serverless File API - AxeonMedia

Ce projet implémente une architecture Cloud native et **serverless** pour la gestion de fichiers. L'objectif est de fournir une API performante, scalable et sécurisée pour l'upload et la gestion de ressources numériques, entièrement automatisée via l'Infrastructure as Code (IaC).

## 🚀 Architecture Technique

L'infrastructure repose sur les services **Amazon Web Services (AWS)** et est déployée de manière modulaire :

* **API Gateway** : Point d'entrée de l'API (REST).
* **AWS Lambda** : Logique métier (Backend en Python).
* **Amazon S3** : Stockage persistant des fichiers.
* **DynamoDB** : Indexation et métadonnées des fichiers.
* **Terraform** : Provisionnement complet de l'infrastructure.

## 📁 Structure du Projet

Le dépôt est organisé comme suit :

* **`/infra`** : Contient les fichiers de configuration Terraform (`main.tf`, `variables.tf`, `outputs.tf`).
* **`/app`** : Interface utilisateur (Frontend HTML/CSS/JS) pour l'interaction avec l'API.
* **`/.github/workflows`** : Pipelines CI/CD pour le déploiement automatisé des ressources.
* **`.gitignore`** : Exclusion des fichiers sensibles (ex: `.tfstate`).

## 🛠️ Installation et Déploiement

### Prérequis
* Terraform v1.14.7+
* AWS CLI configuré avec les accès appropriés.

### Étapes
1.  Cloner le dépôt :
    ```bash
    git clone [https://github.com/kenzathr/serverless-file-api-Axeonmedia.git](https://github.com/kenzathr/serverless-file-api-Axeonmedia.git)
    ```
2.  Initialiser Terraform :
    ```bash
    cd infra
    terraform init
    ```
3.  Déployer l'infrastructure :
    ```bash
    terraform apply
    ```

## 📝 Auteur
* **Kanza Tahri Joutey** - *Project & Operations Manager*
