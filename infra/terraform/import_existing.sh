#!/bin/bash
# Script para importar recursos existentes no Terraform

set -e

echo "=== Verificando e importando recursos existentes ==="

# Contador para recursos não encontrados
MISSING_RESOURCES=0

resource_exists_in_state() {
    terraform state show "$1" &>/dev/null
}

if ! resource_exists_in_state "aws_key_pair.deployer"; then
    echo "Verificando se key pair 'deployer' existe na AWS..."
    if aws ec2 describe-key-pairs --key-names "deployer" &>/dev/null; then
        echo "Key pair encontrada. Importando para o Terraform state..."
        terraform import aws_key_pair.deployer deployer
    else
        echo "Key pair não encontrada na AWS. Será criada pelo Terraform."
        MISSING_RESOURCES=$((MISSING_RESOURCES + 1))
    fi
else
    echo "Key pair já existe no Terraform state."
fi

if ! resource_exists_in_state "aws_security_group.swarm_sg"; then
    echo "Verificando se security group 'swarm-sg' existe na AWS..."
    SG_ID=$(aws ec2 describe-security-groups --group-names "swarm-sg" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "None")
    if [ "$SG_ID" != "None" ] && [ "$SG_ID" != "" ]; then
        echo "Security group encontrado (ID: $SG_ID). Importando para o Terraform state..."
        terraform import aws_security_group.swarm_sg "$SG_ID"
    else
        echo "Security group não encontrado na AWS. Será criado pelo Terraform."
        MISSING_RESOURCES=$((MISSING_RESOURCES + 1))
    fi
else
    echo "Security group já existe no Terraform state."
fi

for i in 0 1 2; do
    if ! resource_exists_in_state "aws_instance.swarm[$i]"; then
        echo "Verificando se instância swarm-node-$i existe na AWS..."
        INSTANCE_ID=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=swarm-node-$i" "Name=instance-state-name,Values=running,pending" \
            --query 'Reservations[0].Instances[0].InstanceId' \
            --output text 2>/dev/null || echo "None")
        
        if [ "$INSTANCE_ID" != "None" ] && [ "$INSTANCE_ID" != "" ] && [ "$INSTANCE_ID" != "null" ]; then
            echo "Instância encontrada (ID: $INSTANCE_ID). Importando para o Terraform state..."
            terraform import "aws_instance.swarm[$i]" "$INSTANCE_ID"
        else
            echo "Instância swarm-node-$i não encontrada na AWS."
            MISSING_RESOURCES=$((MISSING_RESOURCES + 1))
        fi
    else
        echo "Instância swarm-node-$i já existe no Terraform state."
    fi
done

echo "=== Importação concluída ==="
echo "=== Executando terraform plan para verificar estado ==="

# Executa terraform plan e captura o output
PLAN_OUTPUT=$(terraform plan -detailed-exitcode 2>&1) || PLAN_EXIT_CODE=$?

# terraform plan exit codes:
# 0 = No changes, 1 = Error, 2 = Changes present
case ${PLAN_EXIT_CODE:-0} in
    0)
        echo "✅ Terraform plan: Nenhuma mudança necessária - infraestrutura está sincronizada"
        echo "Recursos encontrados e importados com sucesso!"
        ;;
    1)
        echo "❌ Terraform plan: Erro detectado"
        echo "$PLAN_OUTPUT"
        echo "Saindo com exit code 2 devido a erro no plan"
        exit 2
        ;;
    2)
        echo "⚠️ Terraform plan: Mudanças detectadas"
        echo "$PLAN_OUTPUT"
        
        # Verifica se há recursos para criar (indicando recursos não encontrados na AWS)
        if echo "$PLAN_OUTPUT" | grep -q "will be created"; then
            echo "❌ Recursos não encontrados na AWS serão criados pelo Terraform"
            echo "Recursos faltando: $MISSING_RESOURCES"
            echo "Saindo com exit code 2 - recursos não encontrados conforme esperado"
            exit 2
        else
            echo "✅ Apenas modificações/updates detectadas - recursos existem na AWS"
        fi
        ;;
esac

echo "=== Verificação concluída com sucesso ==="
echo "Total de recursos não encontrados na AWS: $MISSING_RESOURCES"

# Se muitos recursos estão faltando, pode indicar problema
if [ $MISSING_RESOURCES -gt 1 ]; then
    echo "⚠️ Aviso: $MISSING_RESOURCES recursos não foram encontrados na AWS"
    echo "Isso pode indicar que a infraestrutura não foi provisionada ainda"
    exit 2
fi

exit 0