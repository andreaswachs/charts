

.PHONY: build
build: index

.PHONY: index
index: package
	helm repo index . --url https://andreaswachs.github.io/charts

.PHONY: package
package: charts/gated-deployment
package:
	mv *.tgz packages

.PHONY: charts/gated-deployment
charts/gated-deployment:
	helm package charts/gated-deployment
