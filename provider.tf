provider "aws" {
  alias   = "source"
  region  = var.source_region
  profile = "source"
}

provider "aws" {
  alias   = "dest"
  region  = var.dest_region
  profile = "dest"
}
