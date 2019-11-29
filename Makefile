all:

change-version:
	bin/change-version.sh $(version)

package:
	bin/package.sh $(version)

deploy:
	bin/deploy.sh $(version)
