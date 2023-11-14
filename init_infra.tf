


#resource "null_resource" "execute_script" {
#  // This resource doesn't create anything but can be used to run a local-exec provisioner
#
#  depends_on = [
#    some_resource.example1,
#    another_resource.example2,
#  ]
#
#  provisioner "local-exec" {
#    command = "python3 your_script.py"
#  }
#}