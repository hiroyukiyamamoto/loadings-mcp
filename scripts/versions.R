if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
print(sessionInfo())
print(installed.packages()[, c("Package", "Version")])
