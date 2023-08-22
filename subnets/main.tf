resource "aws_subnet" "main" {
  vpc_id     = var.vpc_id
  count = length(var.cidr_block)
  cidr_block = var.cidr_block[count.index]

  tags =merge(var.tags, {Name = "${var.env}-${var.name}-${count.index}"})

}