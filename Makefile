

.PHONY: build
build: index

.PHONY: index
index: package
	helm repo index . --url https://andreaswachs.github.io/charts

.PHONY: package
package: charts/gated-deployment charts/https-service
package:
	mv *.tgz packages

.PHONY: charts/gated-deployment
charts/gated-deployment:
	helm package charts/gated-deployment

.PHONY: charts/https-service
charts/https-service:
	helm package charts/https-service
