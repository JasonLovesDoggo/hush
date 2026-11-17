.PHONY: app install run release clean

app:
	./scripts/bundle.sh

install: app
	@pkill -x Hush 2>/dev/null || true
	rm -rf /Applications/Hush.app
	cp -R build/Hush.app /Applications/
	open /Applications/Hush.app

run: app
	@pkill -x Hush 2>/dev/null || true
	open build/Hush.app

release: app
	cd build && ditto -c -k --keepParent Hush.app Hush.zip

clean:
	rm -rf .build build
