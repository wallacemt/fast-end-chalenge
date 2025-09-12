#!/bin/bash
# Script para importar recursos existentes no Terraform

set -e

echo "=== Verificando e importando recursos existentes ==="
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
        fi
    else
        echo "Instância swarm-node-$i já existe no Terraform state."
    fi
done

echo "=== Importação concluída ==="
echo "Execute 'terraform plan' para verificar se há mudanças pendentes."