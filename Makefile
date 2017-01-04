.PHONY: package
package:
	helm package common
	helm keybase sign common-*.tgz
	mv common-* docs
	cd docs && helm repo index . --url https://technosophos.github.io/common-chart/
