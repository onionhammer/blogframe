
all: *.nim
	nimrod c webframe

binrelease: *.nim
	nimrod \
		-d:release \
		--passC:-Ofast \
		c webframe

release: binrelease
	strip webframe.exe -o webframe.exe
	upx -9 webframe.exe

blogtests: blogtests.nim
	nimrod c blogtests


clean:
	rm -rf *.exe nimcache