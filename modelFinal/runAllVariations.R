listfiles <- list.files()[grep("version4.1",list.files())]
listfiles <- listfiles[-grep("timeStep",listfiles)]
listfiles

for (file in listfiles) {
  print(file)
  source(file)
}
