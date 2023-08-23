resource "aws_subnet" "main" {
  vpc_id            = var.vpc_id
  count             = length(var.cidr_block)
  cidr_block        = var.cidr_block[count.index]
  availability_zone = var.azs[count.index]

  tags =merge(var.tags, {Name = "${var.env}-${var.name}-subnet-${count.index+1}"})
}
resource "aws_route_table" "main" {
  count  = length(var.cidr_block)
  vpc_id = var.vpc_id

  tags = merge(var.tags, { Name = "${var.env}-${var.name}-rt-${count.index+1}" })
}
resource "aws_route_table_association" "associate" {
  count          = length(var.cidr_block)
  subnet_id      = aws_subnet.main[count.index].id
  route_table_id = aws_route_table.main[count.index].id
}