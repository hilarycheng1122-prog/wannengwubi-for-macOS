.PHONY: check install-config install-prediction package prediction prediction-alpha

check:
	./scripts/check.sh

install-config:
	./scripts/install-config.sh

install-prediction:
	./scripts/install-config.sh --prediction

package:
	./scripts/build-package.sh

prediction:
	./scripts/build-predict-db.sh

prediction-alpha:
	./scripts/fetch-predict-alpha.sh
