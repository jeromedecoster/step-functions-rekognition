ZIP=sharp-0.24.1.zip

help:
	grep --extended-regexp '^[a-zA-Z]+:.*#[[:space:]].*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN { FS = ":.*#[[:space:]]*" } { printf "\033[1;32m%-12s\033[0m%s\n", $$1, $$2 }'

init: # terraform init + download sharp lambda layer
	terraform init
	if [ ! -f "./layers/$(ZIP)" ] ; then \
		mkdir --parents layers ; \
		cd layers ; \
		curl --location \
        	"https://github.com/jeromedecoster/sharp-lambda-layer/releases/download/v0.24.1/sharp-0.24.1-for-node-12.zip" \
			--output $(ZIP) ; \
	fi

validate: # terraform format then validate
	terraform fmt -recursive
	terraform validate

apply: # terraform plan then apply with auto approve + create rekognition collection
	terraform plan -out=terraform.plan
	terraform apply -auto-approve terraform.plan
	./create-collection.sh 

upload: # upload alice1.jpg to the S3 bucket
	./upload.sh alice1.jpg

alice: # upload all alice images
	./upload.sh alice1.jpg alice2.jpg alice3.jpg \
				alice4.jpg alice5.jpg alice6.jpg \
				alice7.jpg alice8.jpg alice9.jpg

brooke: # upload all brooke images
	./upload.sh brooke1.jpg brooke2.jpg \
				brooke3.jpg brooke4.jpg brooke5.jpg

carole: # upload all carole images
	./upload.sh carole1.jpg carole2.jpg carole3.jpg \
				carole4.jpg carole5.jpg carole6.jpg

diane: # upload all diane images
	./upload.sh diane1.jpg diane2.jpg \
				diane3.jpg diane4.jpg diane5.jpg

emma: # upload all emma images
	./upload.sh emma1.jpg emma2.jpg emma3.jpg emma4.jpg \
				emma5.jpg emma6.jpg emma7.jpg emma8.jpg

fanny: # upload all fanny images
	./upload.sh fanny1.jpg fanny2.jpg fanny3.jpg fanny4.jpg \
				fanny5.jpg fanny6.jpg fanny7.jpg fanny8.jpg \
				fanny9.jpg fanny10.jpg

gemma: # upload all gemma images
	./upload.sh gemma1.jpg gemma2.jpg gemma3.jpg \
				gemma4.jpg gemma5.jpg gemma6.jpg

helen: # upload all helen images
	./upload.sh helen1.jpg helen2.jpg helen3.jpg \
				helen4.jpg helen5.jpg

squirrel: # upload the squirrel image
	./upload.sh squirrel1.jpg

upload-all: carole diane emma fanny gemma helen squirrel # upload all images

invoke: # test event for the lambda on-upload with alice1.jpg
	./invoke.sh alice1.jpg

etag: # delete dynamodb item of alice1.jpg 
	./delete-etag.sh

.SILENT: