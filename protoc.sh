#!/bin/bash

SERVICE_NAME=$1
RELEASE_VERSION=$2
USER_NAME=$3
EMAIL=$4

git config user.name "$USER_NAME"
git config user.email "$EMAIL"

git fetch --all && git checkout main

sudo apt-get install -y protobuf-compiler golang-goprotobuf-dev
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Проверка существования директорий
if [ ! -d "./${SERVICE_NAME}" ]; then
  echo "Директория ./${SERVICE_NAME} не существует."
  exit 1
fi

# генерируем код из proto файлов
protoc --go_out=./golang --go_opt=paths=source_relative \
 --go-grpc_out=./golang --go-grpc_opt=paths=source_relative \
 ./${SERVICE_NAME}/*.proto

if [ ! -d "golang/${SERVICE_NAME}" ]; then
  echo "Директория golang/${SERVICE_NAME} не существует."
  exit 1
fi

cd golang/${SERVICE_NAME}

go mod init \
 github.com/asphodex/protoc/golang/${SERVICE_NAME} || true

go mod tidy

cd ../../

git add . && git commit -am "proto update" || true
git push origin HEAD:main
git tag -fa golang/${SERVICE_NAME}/${RELEASE_VERSION} \
  -m "golang/${SERVICE_NAME}/${RELEASE_VERSION}"

git push origin refs/tags/golang/${SERVICE_NAME}/${RELEASE_VERSION}