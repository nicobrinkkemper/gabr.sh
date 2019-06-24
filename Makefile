.PHONY: all
all: gabr gabr.linux git bats shdoc
# submodules to bin
bats: ./modules/bats-core/libexec/bats-core/
	cp ./modules/bats-core/libexec/bats-core/* ./bin
shdoc: ./modules/shdoc/shdoc
	cp ./modules/shdoc/shdoc ./bin
# shdoc documentation
gabr: gabr.sh
	./bin/shdoc < gabr.sh > GABR.md
gabr.linux: gabr.linux.sh
	./bin/shdoc < gabr.sh > GABR.md
git: ./example/git.sh
	./bin/shdoc < ./example/git.sh > ./example/GIT.md