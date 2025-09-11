# FAST End Challenge

Este projeto provisiona infraestrutura na AWS com **Terraform**, configura e deploya uma aplicação em **Docker Swarm** com **Ansible**, e automatiza **CI/CD com GitHub Actions**.

---

## 🔧 Pré-requisitos

- [Terraform](https://developer.hashicorp.com/terraform/tutorials)
- [Ansible](https://docs.ansible.com/)
- [Docker](https://docs.docker.com/get-docker/) (local para testes)
- Conta AWS com credenciais configuradas (`aws configure`)
- Conta Docker Hub ou AWS ECR para push da imagem

---

## ⚙️ Passo 1 — Provisionar infraestrutura (Terraform)

1. Gere uma chave SSH:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ./infra/terraform/deploy_key
   ```
   - Isso cria deploy_key e deploy_key.pub.
2. Ajuste variables.tf:
   ```bash
       variable "key_name" { default = "deployer" }
       variable "public_key_path" { default = "infra/terraform/deploy_key.pub" }
   ```
3. Execute:
   ```bash
       cd /terraform
       terraform init
       terraform apply -auto-approve
   ```
4. Anote os IPs de saída (swarm_public_ips).

## ⚙️ Passo 2 — Configurar cluster (Ansible)

1. Edite infra/ansible/inventory.ini:
   ```
   [managers]
   manager ansible_host=<IP_MANAGER> ansible_user=ubuntu

   [workers]
   worker1 ansible_host=<IP_WORKER1> ansible_user=ubuntu
   worker2 ansible_host=<IP_WORKER2> ansible_user=ubuntu

   ```
2. Rode o playbook:
   ```bash
       cd infra/ansible
       ansible-playbook -i inventory.ini playbook.yml --private-key ../terraform/deploy_key
   ```
3. Verifique no manager:
   ```bash
   ssh -i infra/terraform/deploy_key ubuntu@<IP_MANAGER>
   docker node ls
   docker service ls
   ```

## ⚙️ Passo 3 — Configurar CI/CD (GitHub Actions)

- No GitHub, vá em Settings > Secrets and variables > Actions.
  Adicione os seguintes secrets:

```DOCKERHUB_USERNAME → seu usuário Docker Hub

DOCKERHUB_TOKEN → token do Docker Hub

SSH_PRIVATE_KEY → conteúdo de deploy_key (privada)

SWARM_MANAGER_IP → IP público do manager
```

- A pipeline funciona assim:

  - CI (.ci/ci.yaml): builda e publica imagem no Docker Hub.

  - CD (.ci/cd.yaml): conecta ao manager e faz docker stack deploy.

- Para disparar:
  - git add .
  - git commit -m "primeiro deploy"
  - git push origin main

## ✅ Checklist final

- Subiu infraestrutura com Terraform

- Configurou cluster com Ansible

- Publicou imagem com CI

- Deploy automático com CD

- Aplicação acessível no manager

- Monitoramento configurado (CloudWatch ou Prometheus)
