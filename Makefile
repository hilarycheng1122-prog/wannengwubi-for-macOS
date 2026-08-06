.PHONY: check install-config package prediction

check:
	./scripts/check.sh

install-config:
	./scripts/install-config.sh

package:
	./scripts/build-package.sh

prediction:
	./scripts/build-predict-db.sh

