NAME := HighSign
PLATFORM := iphoneos
SCHEMES := Ksign
TMP := $(TMPDIR)/$(NAME)
STAGE := $(TMP)/stage
APP := $(TMP)/Build/Products/Release-$(PLATFORM)

.PHONY: all clean $(SCHEMES)

all: $(SCHEMES)

clean:
	rm -rf "$(TMP)"
	rm -rf packages
	rm -rf Payload

deps:
	rm -rf deps || true
	mkdir -p deps
	curl -L -o deps/server.crt https://backloop.dev/backloop.dev-cert.crt || true
	curl -L -o deps/server.key1 https://backloop.dev/backloop.dev-key.part1.pem || true
	curl -L -o deps/server.key2 https://backloop.dev/backloop.dev-key.part2.pem || true
	cat deps/server.key1 deps/server.key2 > deps/server.pem 2>/dev/null || true
	rm -f deps/server.key1 deps/server.key2
	echo "*.backloop.dev" > deps/commonName.txt
	mkdir -p Zsign
	echo "MIT License" > Zsign/LICENSE_LC || true
	sed -i '' 's/name: "Zsign",/name: "Zsign",\n\t\t.library(name: "ZsignSwift", targets: ["Zsign"]),/' Zsign/Package.swift 2>/dev/null || true

$(SCHEMES): deps
	xcodebuild \
	    -project Ksign.xcodeproj \
	    -scheme "$@" \
	    -configuration Release \
	    -arch arm64 \
	    -sdk $(PLATFORM) \
	    -derivedDataPath $(TMP) \
	    -skipPackagePluginValidation \
	    CODE_SIGNING_ALLOWED=NO \
	    ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO

	rm -rf Payload
	rm -rf "$(STAGE)/"
	mkdir -p "$(STAGE)/Payload"

	mv "$(APP)/$@.app" "$(STAGE)/Payload/HighSign.app"

	chmod -R 0755 "$(STAGE)/Payload/HighSign.app"
	codesign --force --sign - --timestamp=none "$(STAGE)/Payload/HighSign.app"

	cp deps/* "$(STAGE)/Payload/HighSign.app/" || true

	rm -rf "$(STAGE)/Payload/HighSign.app/_CodeSignature"
	ln -sf "$(STAGE)/Payload" Payload
	
	mkdir -p packages
	zip -r9 "packages/HighSign.ipa" Payload