locals {
  image_uri = "${var.acr_login_server}/${var.container_image_repository}@${var.container_image_digest}"
}