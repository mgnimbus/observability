#!/usr/bin/env bash
# Delete EBS volumes orphaned by the EKS EBS CSI driver after a cluster teardown.
#
# `terraform destroy` of _1_eks removes the cluster before its StatefulSet PVCs
# (loki/mimir) are deleted, so the CSI-provisioned volumes are left `available`
# and keep billing 24/7. This sweep reclaims them — and any accumulated backlog
# from earlier teardowns.
#
# SAFETY: a volume can also be transiently `available` while a StatefulSet pod
# reschedules onto a new node (e.g. spot interruption), and the CSI driver will
# reattach it. So we NEVER delete a volume whose `ebs.csi.aws.com/cluster-name`
# tag belongs to a *currently running* EKS cluster. Only volumes from clusters
# that no longer exist are deleted. This makes the script safe to run at any
# time, including while a live cluster is up.
#
# Env:
#   AWS_REGION  target region (default: ap-south-2)
#   DRY_RUN     if "true", list what would be deleted but do not delete (default: false)
set -euo pipefail

REGION="${AWS_REGION:-ap-south-2}"
DRY_RUN="${DRY_RUN:-false}"

# Names of EKS clusters that currently exist — their volumes are off-limits.
mapfile -t live_clusters < <(aws eks list-clusters --region "$REGION" \
  --query 'clusters' --output text | tr '\t' '\n' | sed '/^$/d')

is_live() {
  local name="$1"
  for c in "${live_clusters[@]:-}"; do
    [ "$c" = "$name" ] && return 0
  done
  return 1
}

# All detached CSI volumes, paired with their owning cluster name.
# Output lines: "<volume-id>\t<cluster-name>"  (cluster-name may be "None").
mapfile -t rows < <(aws ec2 describe-volumes \
  --region "$REGION" \
  --filters "Name=status,Values=available" \
            "Name=tag:ebs.csi.aws.com/cluster,Values=true" \
  --query 'Volumes[].[VolumeId, Tags[?Key==`ebs.csi.aws.com/cluster-name`]|[0].Value]' \
  --output text)

to_delete=()
for row in "${rows[@]:-}"; do
  [ -z "$row" ] && continue
  vol="$(awk '{print $1}' <<<"$row")"
  cluster="$(awk '{print $2}' <<<"$row")"
  if [ -n "${cluster:-}" ] && [ "$cluster" != "None" ] && is_live "$cluster"; then
    echo "↳ skipping $vol — owned by live cluster $cluster"
    continue
  fi
  to_delete+=("$vol")
done

if [ "${#to_delete[@]}" -eq 0 ]; then
  echo "✅ No orphaned CSI EBS volumes to delete in $REGION."
  exit 0
fi

echo "Found ${#to_delete[@]} orphaned CSI volume(s) in $REGION:"
printf '  %s\n' "${to_delete[@]}"

if [ "$DRY_RUN" = "true" ]; then
  echo "DRY_RUN=true — not deleting."
  exit 0
fi

for vol in "${to_delete[@]}"; do
  aws ec2 delete-volume --region "$REGION" --volume-id "$vol"
  echo "🗑️  deleted $vol"
done

echo "✅ Deleted ${#to_delete[@]} orphaned volume(s)."
