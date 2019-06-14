GABR.md: gabr.sh
	./modules/shdoc/shdoc < gabr.sh > GABR.md
GABR.LINUX.md: gabr.linux.sh
	./modules/shdoc/shdoc < gabr.linux.sh > GABR.LINUX.md
GIT.md: ./example/git.sh
	./modules/shdoc/shdoc < ./example/git.sh > ./example/GIT.md