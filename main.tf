resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = merge(var.tags, {Name = "${var.env}-VPC"})
}

module "subnets" {
  source = "./subnets"
  for_each = var.subnets
  vpc_id = aws_vpc.main.id
  cidr_block = each.value["cidr_block"]
  azs = each.value["azs"]
  name = each.value["name"]

  env = var.env
  tags = var.tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {Name = "${var.env}-IGW"})
}
resource "aws_eip" "ngw" {
  //count = length(lookup(lookup(var.subnets, "public",null),"cidr_block",0))
  count = length(var.subnets["public"].cidr_block)
  tags = merge(var.tags, { Name = "${var.env}-NGW" })
}

resource "aws_nat_gateway" "ngw" {
  count         = length(var.subnets["public"].cidr_block)
  allocation_id = aws_eip.ngw[count.index].id
  subnet_id     = module.subnets["public"].subnet_ids[count.index]

  tags = merge(var.tags, { Name = "${var.env}-NGW" })
}
resource "aws_route" "igw" {
  count                  = length(module.subnets["public"].route_table_ids)
  route_table_id         = module.subnets["public"].route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
resource "aws_route" "ngw" {
  count                  = length(local.all_private_subnet_ids)
  route_table_id         = local.all_private_subnet_ids[count.index]
  nat_gateway_id         = element(aws_nat_gateway.ngw.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_vpc_peering_connection" "peer" {
  peer_vpc_id   = var.default_vpc_id
  vpc_id        = aws_vpc.main.id
  auto_accept   = true
}
resource "aws_route" "peering_connection_route" {
  count                  = length(local.all_private_subnet_ids)
  route_table_id         = element(local.all_private_subnet_ids, count.index)
  destination_cidr_block = var.default_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
resource "aws_route" "peering_connection_route_in_default_route" {
  route_table_id         = var.default_vpc_rtid
  destination_cidr_block = var.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}