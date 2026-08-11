.PHONY: check install-config install-prediction install-personal-learning install-universal-learning reset-personal-learning package prediction prediction-alpha

check:
	./scripts/check.sh

install-config:
	./scripts/install-config.sh

install-prediction:
	./scripts/install-config.sh --prediction

install-personal-learning:
	./scripts/install-config.sh --personal-learning

install-universal-learning:
	./scripts/install-config.sh --universal-learning

reset-personal-learning:
	./scripts/reset-personal-learning.sh

package:
	./scripts/build-package.sh

prediction:
	./scripts/build-predict-db.sh

prediction-alpha:
	./scripts/fetch-predict-alpha.sh
